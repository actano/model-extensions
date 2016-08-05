removeFirstChar = (string) ->
    string.slice 1

uppercaseFirstChar = (string) ->
    string.charAt(0).toUpperCase() + removeFirstChar string

exports.getSetterName = getSetterName = (propertyName) ->
    "set#{uppercaseFirstChar propertyName}"

exports.getGetterName = getGetterName = (propertyName) ->
    "get#{uppercaseFirstChar propertyName}"

isPropertyForAccessorCreation = (propertyName, propertyValue) ->
    return (propertyValue not instanceof Function) and (propertyName.charAt(0) is '_')

getPropertiesForAccessorCreation = (prototype) ->
    propertyNames = for propertyName, propertyValue of prototype when isPropertyForAccessorCreation(propertyName, propertyValue)
        removeFirstChar propertyName
    propertyNames = propertyNames.sort()

    return propertyNames

Model = (prototype) ->
    propertiesWithAccessors = getPropertiesForAccessorCreation prototype

    createSetterIfNeeded = (propertyName) ->
        prototype[getSetterName propertyName] ?= (value) ->
            this["_#{propertyName}"] = value

    createGetterIfNeeded = (propertyName) ->
        prototype[getGetterName propertyName] ?= (value) ->
            this["_#{propertyName}"]

    createProperty = (propertyName) ->
        prototype[propertyName] = (value) ->
            if arguments.length > 0
                this[getSetterName propertyName] value
            else
                this[getGetterName propertyName]()

    createFromMap = ->
        prototype.fromMap = (propertyMap = {}) ->
            for propertyName in propertiesWithAccessors when propertyName of propertyMap
                this[getSetterName propertyName] propertyMap[propertyName]

    createToMap = ->
        prototype.toMap = ->
            propertyMap = {}
            for propertyName in propertiesWithAccessors
                propertyMap[propertyName] = this[getGetterName propertyName]()
            propertyMap

    createFromMapBypassSetters = ->
        prototype.fromMapBypassSetters = (propertyMap = {}) ->
            for propertyName in propertiesWithAccessors when propertyName of propertyMap
                this["_#{propertyName}"] = propertyMap[propertyName]

    for propertyName in propertiesWithAccessors
        createGetterIfNeeded propertyName
        createSetterIfNeeded propertyName
        createProperty propertyName

    createFromMap()
    createToMap()
    createFromMapBypassSetters()

    prototype

exports.Model = Model
