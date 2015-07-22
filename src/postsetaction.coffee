lowercaseFirstChar = (string) ->
    string.charAt(0).toLowerCase() + string.slice 1

getPropertyNameOfSetter = (setterName) ->
    lowercaseFirstChar setterName.slice 3

startsWith = (string, prefix) ->
    string.indexOf(prefix) is 0

PostSetAction = (prototype, postSetHook) ->
    extendSetter = (setterName) ->
        originalSetter = prototype[setterName]
        prototype[setterName] = (value) ->
            propertyName = getPropertyNameOfSetter setterName
            oldValue = this["_#{propertyName}"]
            originalSetter.call this, value
            postSetHook.call this, propertyName, value, oldValue
            value

    for setterName of prototype when startsWith setterName, 'set'
        extendSetter setterName

    prototype

module.exports.PostSetAction = PostSetAction
