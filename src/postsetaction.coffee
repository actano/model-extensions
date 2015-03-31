lowercaseFirstChar = (string) ->
    return string.charAt(0).toLowerCase() + string.slice 1

getPropertyNameOfSetter = (setterName) ->
    return lowercaseFirstChar(setterName.slice(3))

startsWith = (candidate, query) ->
    return candidate.indexOf(query) == 0


PostSetAction = (prototype, action) ->

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

module.exports.PostSetAction = PostSetAction
