* Encoding: UTF-8.
* Function to create a data set with the descriptive statistics for
* a set of variables. Also allows you to obtain these separately within
* the levels of a categorical split variable.
* Written by Jamie DeCoster

* Usage: descriptiveDataset(List of variables, List of statistics, Optional split variable)
* List of variables is a list of the variables on which the statistics will be calculated
* List of statistics is a list of statistics that should be calculated on the list of
variables. Valid values are MEAN STDDEV MINIMUM MAXIMUM
SEMEAN VARIANCE SKEWNESS SESKEW RANGE
MODE KURTOSIS SEKURT MEDIAN SUM VALID MISSING
* If the Optional split variable is omitted, then the statistics are calculated on
the full data set. If it is provided, then the statistics are calculated separately for
each level of the split variable

* EXAMPLE 1: descriptiveDataset(["CTHeadSt", "CTPubSch"], 
    ["MEAN", "STDDEV"], e_site)
This command would produce a data set with the mean and standard deviations
of the variables CTHeadST and CTPubSch for each of the levels of the e_site
variable. There would be one line in the data set for each level of e_site

* EXAMPLE 2: descriptiveDataset(["CTHeadSt"], 
    ["MEAN", "STDDEV"])
This command would produce a data set containing the overall mean and 
standard deviation of the CTHeadSt variable. There would only be a single
line in the data set.

***********************
* Version History
***********************
* 2013-04-06 Created
* 2013-09-11 Fixed error with reporting splitvariable
    Fixed problem with variable order
* 2016-12-03 Fixed error with output variable types
* 2016-12-04 Changed program so that it doesn't overwrite 
    existing data sets

set printback=off.
begin program python.
import spss, spssaux, os

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

def getVariableIndex(variable):
   	for t in range(spss.GetVariableCount()):
      if (variable.upper() == spss.GetVariableName(t).upper()):
         return(t)

def getLevels(variable):
    submitstring = """use all.
execute.
SET Tnumbers=values.
OMS SELECT TABLES
/IF COMMANDs=['Frequencies'] SUBTYPES=['Frequencies']
/DESTINATION FORMAT=OXML XMLWORKSPACE='freq_table'.
    FREQUENCIES VARIABLES=%s.
    OMSEND.
SET Tnumbers=Labels.""" %(variable)
    spss.Submit(submitstring)
 
    handle='freq_table'
    context="/outputTree"
#get rows that are totals by looking for varName attribute
#use the group element to skip split file category text attributes
    xpath="//group/category[@varName]/@text"
    values=spss.EvaluateXPath(handle,context,xpath)

# If the original variable was numeric, convert the list to numbers

    varnum=getVariableIndex(variable)
    values2 = []
    if (spss.GetVariableType(varnum) == 0):
      for t in range(len(values)):
         values2.append(int(float(values[t])))
    else:
      for t in range(len(values)):
         values2.append("'" + values[t] + "'")
    spss.DeleteXPathHandle(handle)
    return values2

def descriptiveDataset(variableList, statList, splitvar="None"):
# Valid values for stat are MEAN STDDEV MINIMUM MAXIMUM
# SEMEAN VARIANCE SKEWNESS SESKEW RANGE
# MODE KURTOSIS SEKURT MEDIAN SUM VALID MISSING

# Determine active data set so we can return to it when finished
    activeName = spss.ActiveDataset()

    if (splitvar == "None"):
# Extracting the VALID and MISSING stats from statList
        valid = 0
        missing = 0
        statList2 = []
        for stat in statList:
            if (stat.upper() == "VALID"):
                valid = 1
            elif (stat.upper() == "MISSING"):
                missing = 1
            else:
                statList2.append(stat)

        cmd = "FREQUENCIES VARIABLES="
        for var in variableList:
            cmd = cmd + var + "\n"
        cmd = cmd + "/FORMAT=NOTABLE\n"
        if len(statList2)>0:
            cmd = cmd + "/STATISTICS="""
            for stat in statList2:
                cmd = cmd + stat + "\n"
        cmd = cmd + "/ORDER=ANALYSIS."
        handle,failcode=spssaux.CreateXMLOutput(
		cmd,
		omsid="Frequencies",
		subtype="Statistics",
		visible=False)
        result=spssaux.GetValuesFromXMLWorkspace(
		handle,
		tableSubtype="Statistics",
		cellAttrib="text")

# Extracting values from output
        dt = []
        dtline = []
        varnum = len(variableList)
        statnum = len(statList2)

# Extracting values from output
        dtline = []
        dtline.append(str(sl))
        if (valid == 1):
            for r in result[:varnum]:
                dtline.append(int(float(r)))
        if (missing == 1):
                for r in result[varnum:2*varnum]:
                    dtline.append(int(float(r)))
        if (len(statList2)>0):
                for r in result[2*varnum:]:
                    dtline.append(float(r))
        dt.append(dtline)

 # Determine active data set so we can return to it when finished
        activeName = spss.ActiveDataset()
# Set up data set if it doesn't already exist
        tag,err = spssaux.createXmlOutput('Dataset Display',
omsid='Dataset Display', subtype='Datasets')
        datasetList = spssaux.getValuesFromXmlWorkspace(tag, 'Datasets')

        if ("Descriptives" not in datasetList):
            spss.StartDataStep()
            datasetObj = spss.Dataset(name=None)
            dsetname = datasetObj.name
            spss.SetActive(datasetObj)
            if (valid == 1):
                for var in variableList:
                    datasetObj.varlist.append(var + "_" + 'VALID',0)
            if (missing == 1):
                for var in variableList:
                    datasetObj.varlist.append(var + "_" + 'MISSING',0)
            for stat in statList2:
                for var in variableList:
                    datasetObj.varlist.append(var + "_" + stat,0)
            spss.EndDataStep()
            submitstring = """dataset activate {0}.
dataset name Descriptives.""".format(dsetname)
            spss.Submit(submitstring)

        spss.StartDataStep()     
        datasetObj = spss.Dataset(name = "*")
        spss.SetActive(datasetObj)
        for line in dt:
           datasetObj.cases.append(line)
        spss.EndDataStep()

        submitstring = """dataset activate {0}.
use all.""".format(activeName)
        spss.Submit(submitstring)

        
    else: # Has a split variable

# Extracting the VALID and MISSING stats from statList
        valid = 0
        missing = 0
        statList2 = []
        for stat in statList:
            if (stat.upper() == "VALID"):
                valid = 1
            elif (stat.upper() == "MISSING"):
                missing = 1
            else:
                statList2.append(stat)

        slevels = getLevels(splitvar)
        varnum = len(variableList)
        statnum = len(statList2)
        dt = []
        for sl in slevels:
            submitstring = """USE ALL.
COMPUTE filter_$=(%s=%s).
FILTER BY filter_$.
EXECUTE.""" %(splitvar, sl)
            spss.Submit(submitstring)

            cmd = "FREQUENCIES VARIABLES="
            for var in variableList:
                cmd = cmd + var + "\n"
            cmd = cmd + "/FORMAT=NOTABLE\n"
            if len(statList2)>0:
                cmd = cmd + "/STATISTICS="""
                for stat in statList2:
                    cmd = cmd + stat + "\n"
            cmd = cmd + "/ORDER=ANALYSIS."
            print cmd
            handle,failcode=spssaux.CreateXMLOutput(
		cmd,
		omsid="Frequencies",
		subtype="Statistics",
		visible=False)
            result=spssaux.GetValuesFromXMLWorkspace(
		handle,
		tableSubtype="Statistics",
		cellAttrib="text")

# Extracting values from output
            dtline = []
            dtline.append(str(sl))
            if (valid == 1):
                for r in result[:varnum]:
                    dtline.append(int(float(r)))
            if (missing == 1):
                    for r in result[varnum:2*varnum]:
                        dtline.append(int(float(r)))
            if (len(statList2)>0):
                    for r in result[2*varnum:]:
                        dtline.append(float(r))
            dt.append(dtline)

# Determine active data set so we can return to it when finished
        activeName = spss.ActiveDataset()
# Set up data set if it doesn't already exist
        tag,err = spssaux.createXmlOutput('Dataset Display',
omsid='Dataset Display', subtype='Datasets')
        datasetList = spssaux.getValuesFromXmlWorkspace(tag, 'Datasets')

        if ("Descriptives" not in datasetList):
            spss.StartDataStep()
            datasetObj = spss.Dataset(name=None)
            dsetname = datasetObj.name
            spss.SetActive(datasetObj)
            datasetObj.varlist.append(splitvar, 50)
            if (valid == 1):
                for var in variableList:
                    datasetObj.varlist.append(var + "_" + 'VALID',0)
            if (missing == 1):
                for var in variableList:
                    datasetObj.varlist.append(var + "_" + 'MISSING',0)
            for stat in statList2:
                for var in variableList:
                    datasetObj.varlist.append(var + "_" + stat,0)
            spss.EndDataStep()
            submitstring = """dataset activate {0}.
dataset name Descriptives.""".format(dsetname)
            spss.Submit(submitstring)

        spss.StartDataStep()
        datasetObj = spss.Dataset(name = "Descriptives")
        spss.SetActive(datasetObj)

        for line in dt:
            if (len(line) == len(variableList)*len(statList)+1):
                datasetObj.cases.append(line)
        spss.EndDataStep()

        submitstring = """dataset activate {0}.
use all.""".format(activeName)
        spss.Submit(submitstring)

end program python.
set printback=on.
