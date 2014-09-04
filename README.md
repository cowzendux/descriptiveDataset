#descriptiveDataset

SPSS Python Extension function to create a data set with the descriptive statistics for a set of variables

This function also allows you to obtain these separately within the levels of a categorical split variable.

This and other SPSS Python Extension functions can be found at http://www.stat-help.com/python.html

##Usage
**descriptiveDataset(variableList, statList, splitvar)**
* "variableList" is a list of strings indicating the variables on which the statistics will be calculated. This argument is required.
* "statList" is a list of strings indicating the statistics that should be calculated for each of the variables. This argument is required. Acceptable values for the items in this list are
    * MEAN = Mean
    * STDDEV = Standard deviation
    * MINIMUM = Minimum value
    * MAXIMUM = Maximum value
    * SEMEAN = Standard error of the mean
    * VARIANCE = Variance
    * SKEWNESS = Skewness
    * SESKEW = Standard error of the skewness
    * RANGE = Range
    * MODE = Mode 
    * KURTOSIS = Kurtosis
    * SEKURT = Standard error of the kurtosis
    * MEDIAN = Median
    * SUM = Sum of all cases
    * VALID = Number of cases with non-missing values
    * MISSING = Number of cases with missing values
* "splitvar" is an optional string argument.  If it is not provided, then the statistics will be provided only for the full data set. If it is provided, then the statistics will be calculated separately for each level of the splitvar Variable.

##Example 1
**descriptiveDataset(["descriptiveDataset(["CTHeadSt", "CTPubSch"], ["MEAN", "STDDEV"], e_site)**
* This command would produce a data set with the mean and standard deviations of the variables CTHeadST and CTPubSch for each of the levels of the e_site variable. There would be one line in the data set for each level of e_site.

##EXAMPLE 2: 
**descriptiveDataset(["descriptiveDataset(["CTHeadSt"], ["MEAN", "STDDEV"])**
* This command would produce a data set containing the overall mean and standard deviation of the CTHeadSt variable. There would only be a single line in the data set.
