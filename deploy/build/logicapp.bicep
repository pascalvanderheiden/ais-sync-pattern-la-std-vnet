@minLength(3)
@maxLength(11)
param namePrefix string
param location string

var logicAppName = '${namePrefix}$-la'
