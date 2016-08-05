{expect} = require 'chai'
sinon = require 'sinon'

{Model, PostSetAction} = require '../src/index'

class SimpleModel
    _attr1: null
    _attr2: null
    _func: ->

    constructor: (propertyMap) ->
        @fromMap propertyMap

class ComplexModel
    _existing1: null
    _existing2: null

    setExisting1: (value) ->
        @_existing1 = "#{value}_set"

    getExisting2: ->
        "#{@_existing2}_get"

class ExtendingModel extends SimpleModel
    _attr3: null

    constructor: (propertyMap = {}) ->
        super

class ModelWithDefaultValues
    _attr1: null
    _attr2: null

    constructor: (propertyMap) ->
        @_attr1 = 10
        @_attr2 = 10
        @fromMap propertyMap

expectFunction = (clazz, funcName) ->
    func = clazz.prototype[funcName]
    expect(func, "expected #{funcName} to exist").to.exist
    expect(func, "expected #{funcName} to be a function").to.be.instanceOf Function

describe 'model-extensions', ->
    Model SimpleModel.prototype
    Model ComplexModel.prototype
    Model ExtendingModel.prototype
    Model ModelWithDefaultValues.prototype

    describe 'Model', ->
        it 'should create getter and setter methods', ->
            expectFunction SimpleModel, 'getAttr1'
            expectFunction SimpleModel, 'setAttr1'
            expectFunction SimpleModel, 'getAttr2'
            expectFunction SimpleModel, 'setAttr2'

        it 'should not create getter and setter methods for functions', ->
            expect(SimpleModel.prototype.getFunc, "expected getFunc not exist").to.not.exist
            expect(SimpleModel.prototype.setFunc, "expected setFunc not exist").to.not.exist

        it 'should create from and to map methods', ->
            expectFunction SimpleModel, 'fromMap'
            expectFunction SimpleModel, 'toMap'

        it 'should create property methods', ->
            expectFunction SimpleModel, 'attr1'
            expectFunction SimpleModel, 'attr2'

        it 'should set value with created setters', ->
            model = new SimpleModel()
            model.setAttr1 1
            expect(model._attr1).to.equal 1

        it 'should get value with created getters', ->
            model = new SimpleModel()
            model._attr1 = 1
            expect(model.getAttr1()).to.equal 1

        it 'should use existing setters', ->
            model = new ComplexModel()

            model.setExisting1('test')
            expect(model._existing1).to.equal 'test_set'

        it 'should use existing getters', ->
            model = new ComplexModel()
            model._existing2 = 'test'
            value = model.getExisting2()
            expect(value).to.equal 'test_get'

        it 'should get and set properties via property methods', ->
            model = new SimpleModel()
            model.attr1('test')
            expect(model._attr1).to.equal 'test'
            value = model.attr1()
            expect(value).to.equal 'test'

        it 'should de-serialize and serialize maps', ->
            map = attr1: 1, attr2: 2

            model = new SimpleModel map
            expect(model._attr1).to.equal 1
            expect(model._attr2).to.equal 2

            expect(model.toMap()).to.deep.equal map

        it 'should create getters and setters of subclass', ->
            expectFunction ExtendingModel, 'getAttr3'
            expectFunction ExtendingModel, 'setAttr3'

        it 'should create properties of subclass', ->
            expectFunction ExtendingModel, 'attr3'

        it 'should set super-class properties in sub-class', ->
            model = new ExtendingModel()
            model.attr1 'test'
            expect(model._attr1).to.equal 'test'

        it 'should get super-class properties in sub-class', ->
            model = new ExtendingModel()
            model._attr1 = 'test'
            expect(model.attr1()).to.equal 'test'

        it 'should initialize values from the given map', ->
            model = new ModelWithDefaultValues
                attr1: 42
                attr2: null

            expect(model.attr1()).to.equal 42
            expect(model.attr2()).to.be.null

        describe 'properties for which accessors are created', ->
            class AccessorModel
                _accessorProperty: null
                _anotherAccessorProperty: 1
                otherProperty: 5

            Model AccessorModel.prototype

            it 'should create accessors for properties starting with underscore', ->
                modelInstance = new AccessorModel()

                expect(modelInstance.accessorProperty).to.be.a 'function'

            it 'should not create accessors for properties not starting with underscore', ->
                modelInstance = new AccessorModel
                    otherProperty: 6

                expect(modelInstance.otherProperty).not.to.be.a 'function'
                expect(modelInstance.therProperty).not.to.be.a 'function'

            it 'should set properties when calling fromMapBypassSetters', ->
                model = new AccessorModel()
                model.fromMapBypassSetters accessorProperty: 1, anotherAccessorProperty: null
                expect(model._accessorProperty).to.equal 1
                expect(model._anotherAccessorProperty).to.be.null

            it 'should not set properties which don\'t have accessors when calling fromMapBypassSetters', ->
                model = new AccessorModel()
                model.fromMapBypassSetters otherProperty: 6
                expect(model.otherProperty).to.equal 5

    describe 'PostSetAction', ->
        spy = sinon.spy()
        PostSetAction SimpleModel.prototype, spy
        PostSetAction ExtendingModel.prototype, spy

        expectSpyToBeCalledWith = (postSetProperty, oldValues) ->
            lastSpyCallArgs = spy.lastCall.args
            expect(lastSpyCallArgs[0]).to.equal postSetProperty
            expect(lastSpyCallArgs[1]).to.deep.equal oldValues

        beforeEach ->
            spy.reset()

        it 'should call the post set action', ->
            model = new SimpleModel()

            model.setAttr1 1
            expect(model._attr1).to.equal 1
            expectSpyToBeCalledWith 'attr1', attr1: null, attr2: null

            model.setAttr2 2
            expect(model._attr2).to.equal 2
            expectSpyToBeCalledWith 'attr2', attr1: 1, attr2: null

            model.setAttr2 3
            expect(model._attr2).to.equal 3
            expectSpyToBeCalledWith 'attr2', attr1: 1, attr2: 2

        it 'should call the post set action in sub class', ->
            model = new ExtendingModel()

            model.setAttr1 1
            expect(model._attr1).to.equal 1
            expectSpyToBeCalledWith 'attr1', attr1: null, attr2: null, attr3: null

            model.setAttr3 2
            expect(model._attr3).to.equal 2
            expectSpyToBeCalledWith 'attr3', attr1: 1, attr2: null, attr3: null

            model.setAttr3 3
            expect(model._attr3).to.equal 3
            expectSpyToBeCalledWith 'attr3', attr1: 1, attr2: null, attr3: 2
