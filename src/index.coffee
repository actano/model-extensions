capitalizeFirstLetter = (string) ->
    return string.charAt(0).toUpperCase() + string.slice 1

lowercaseFirstLetter = (string) ->
    return string.charAt(0).toLowerCase() + string.slice 1

removeFirstLetter = (string) ->
    string.slice(1)

startsWith = (candidate, query) ->
    return candidate.indexOf(query) == 0

getSetterName = (propertyName) ->
    upperCasePropertyName = capitalizeFirstLetter propertyName
    return 'set' + upperCasePropertyName

getGetterName = (propertyName) ->
    upperCasePropertyName = capitalizeFirstLetter propertyName
    return 'get' + upperCasePropertyName

getPropertyNameOfSetter = (setterName) ->
    return lowercaseFirstLetter(setterName.slice(3))

Model = (ModelClass) ->
    prototype = ModelClass.prototype

    listSortedPropertyNames = ->
        propertyNames = []
        for propertyKey, propertyValue of prototype
            unless propertyValue instanceof Function
                propertyNames.push removeFirstLetter propertyKey
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

    createToMap = ->
        prototype.toMap = ->
            propertyMap = {}
            propertyNames = listSortedPropertyNames()
            for propertyName in propertyNames
                getterName = getGetterName(propertyName)
                propertyValue = @[getterName]()
                propertyMap[propertyName] = propertyValue
            propertyMap

    propertyNames = listSortedPropertyNames(prototype)

    for propertyName in propertyNames
        do (propertyName) ->
            createGetterIfNeeded(propertyName)
            createSetterIfNeeded(propertyName)
            createProperty(propertyName)
    createFromMap()
    createToMap()

    return prototype

PostSetAction = (ModelClass, action) ->
    prototype = ModelClass.prototype

    listSetterNames = ->
        setterNames = []
        for propertyKey, propertyValue of prototype
            if startsWith(propertyKey, "set")
                setterNames.push(propertyKey)
        setterNames

    postExtendSetter = (setterName, extension) ->
        originalSetter = prototype[setterName]
        prototype[setterName] = (newValue) ->
            propertyName = getPropertyNameOfSetter(setterName)
            oldValue = @["_#{propertyName}"]
            originalSetter.apply(this, [newValue])
            extension.apply(this, [propertyName, newValue, oldValue])
            return newValue

    for setterName in listSetterNames()
        do (setterName) ->
            postExtendSetter(setterName, action)

    return prototype

module.exports = {
    Model
    PostSetAction
}
