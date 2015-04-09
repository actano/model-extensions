uppercaseFirstChar = (string) ->
    return string.charAt(0).toUpperCase() + string.slice 1

getSetterName = (propertyName) ->
    upperCasePropertyName = uppercaseFirstChar propertyName
    return 'set' + upperCasePropertyName

getGetterName = (propertyName) ->
    upperCasePropertyName = uppercaseFirstChar propertyName
    return 'get' + upperCasePropertyName

removeFirstChar = (string) ->
    string.slice(1)

Model = (prototype) ->

    listSortedPropertyNames = ->
        propertyNames = []
        for propertyKey, propertyValue of prototype
            unless propertyValue instanceof Function
                propertyNames.push removeFirstChar propertyKey
        propertyNames = propertyNames.sort()
        return propertyNames

    createSetterIfNeeded = (propertyName) ->
        setterName = getSetterName(propertyName)
        unless prototype[setterName]
            prototype[setterName] = (value) ->
                @["_#{propertyName}"] = value
        prototype[setterName]

    createGetterIfNeeded = (propertyName) ->
        getterName = getGetterName(propertyName)
        unless prototype[getterName]
            prototype[getterName] = (value) ->
                @["_#{propertyName}"]
        prototype[getterName]

    createProperty = (propertyName) ->
        prototype[propertyName] = (value) ->
            if (arguments.length > 0)
                @[getSetterName(propertyName)](value)
            else
                @[getGetterName(propertyName)]()

    createFromMap = ->
        prototype.fromMap = (propertyMap = {}) ->
            propertyNames = listSortedPropertyNames()
            for propertyName in propertyNames
                propertyValue = propertyMap[propertyName]
                setterName = getSetterName(propertyName)
                @[setterName](propertyValue) if propertyValue?
            return

    createToMap = ->
        prototype.toMap = ->
            propertyMap = {}
            propertyNames = listSortedPropertyNames()
            for propertyName in propertyNames
                getterName = getGetterName(propertyName)
                propertyValue = @[getterName]()
                propertyMap[propertyName] = propertyValue
            propertyMap

    createFromMapBypassSetters = ->
        prototype.fromMapBypassSetters = (propertyMap = {}) ->
            propertyNames = listSortedPropertyNames()
            for propertyName in propertyNames
                propertyValue = propertyMap[propertyName]
                @["_#{propertyName}"] = propertyValue if propertyValue?
            return

    propertyNames = listSortedPropertyNames(prototype)

    for propertyName in propertyNames
        do (propertyName) ->
            createGetterIfNeeded(propertyName)
            createSetterIfNeeded(propertyName)
            createProperty(propertyName)
    createFromMap()
    createToMap()
    createFromMapBypassSetters()

    return prototype

module.exports.Model = Model
