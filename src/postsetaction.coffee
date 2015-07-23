lowercaseFirstChar = (string) ->
    string.charAt(0).toLowerCase() + string.slice 1

getPropertyName = (setterName) ->
    lowercaseFirstChar setterName.slice 3

startsWith = (string, prefix) ->
    string.indexOf(prefix) is 0

PostSetAction = (prototype, postSetHook) ->
    getterNames = (getterName for getterName of prototype when startsWith getterName, 'get')
    setterNames = (setterName for setterName of prototype when startsWith setterName, 'set')

    setterNames.forEach (setterName) ->
        originalSetter = prototype[setterName]
        prototype[setterName] = (value) ->
            oldValues = {}
            oldValues[getPropertyName getterName] = this[getterName]() for getterName in getterNames

            originalSetter.call this, value

            postSetHook.call this, getPropertyName(setterName), oldValues

            value

    prototype

module.exports.PostSetAction = PostSetAction
