removeFirstChar = (string) ->
    string.slice 1

uppercaseFirstChar = (string) ->
    string.charAt(0).toUpperCase() + removeFirstChar string

getSetterName = (propertyName) ->
    "set#{uppercaseFirstChar propertyName}"

getGetterName = (propertyName) ->
    "get#{uppercaseFirstChar propertyName}"

Model = (prototype) ->
    propertyNames = for propertyKey of prototype when propertyKey.charAt(0) is '_'
        removeFirstChar propertyKey
    propertyNames = propertyNames.sort()

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
            for propertyName in propertyNames when propertyName of propertyMap
                this[getSetterName propertyName] propertyMap[propertyName]

    createToMap = ->
        prototype.toMap = ->
            propertyMap = {}
            for propertyName in propertyNames
                propertyMap[propertyName] = this[getGetterName propertyName]()
            propertyMap

    createFromMapBypassSetters = ->
        prototype.fromMapBypassSetters = (propertyMap = {}) ->
            for propertyName in propertyNames when propertyName of propertyMap
                this["_#{propertyName}"] = propertyMap[propertyName]

    for propertyName in propertyNames
        createGetterIfNeeded propertyName
        createSetterIfNeeded propertyName
        createProperty propertyName

    createFromMap()
    createToMap()
    createFromMapBypassSetters()

    prototype

exports.Model = Model
