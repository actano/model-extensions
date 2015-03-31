{expect} = require 'chai'
sinon = require 'sinon'

{Model, PostSetAction} = require '../src/index'

class SimpleModel

    _attr1: null
    _attr2: null

    constructor: (propertyMap) ->
        @fromMap(propertyMap)

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

expectFunction = (ModelClass, funcName) ->
    func = ModelClass.prototype[funcName]
    expect(func, "expected #{funcName} to exist").to.be.defined
    expect(func, "expected #{funcName} to be a function").to.be.instanceOf Function

describe "model-extensions", ->

    Model(SimpleModel)
    Model(ComplexModel)
    Model(ExtendingModel)

    describe "Model", ->

        it "should create getter and setter methods", ->
            expectFunction(SimpleModel, "getAttr1")
            expectFunction(SimpleModel, "setAttr1")
            expectFunction(SimpleModel, "getAttr2")
            expectFunction(SimpleModel, "setAttr2")

        it "should create from and to map methods", ->
            expectFunction(SimpleModel, "fromMap")
            expectFunction(SimpleModel, "toMap")

        it "should create property methods", ->
            expectFunction(SimpleModel, "attr1")
            expectFunction(SimpleModel, "attr2")

        it 'should set value with created setters', ->
            model = new SimpleModel()
            model.setAttr1(1)
            expect(model._attr1).to.equal 1

        it 'should get value with created getters', ->
            model = new SimpleModel()
            model._attr1 = 1
            expect(model.getAttr1()).to.equal 1

        it "should use existing setters", ->
            model = new ComplexModel()

            model.setExisting1("test")
            expect(model._existing1).to.equal "test_set"

        it "should use existing getters", ->
            model = new ComplexModel()
            model._existing2 = "test"
            value = model.getExisting2()
            expect(value).to.equal "test_get"

        it "should get and set properties via property methods", ->
            model = new SimpleModel()
            model.attr1("test")
            expect(model._attr1).to.equal "test"
            value = model.attr1()
            expect(value).to.equal "test"

        it "should de-serialize and serialize maps", ->
            map = { attr1: 1, attr2: 2 }

            model = new SimpleModel(map)
            expect(model._attr1).to.equal 1
            expect(model._attr2).to.equal 2

            expect(model.toMap()).to.eql(map)

        it "should create getters and setters of subclass", ->
            expectFunction(ExtendingModel, "getAttr3")
            expectFunction(ExtendingModel, "setAttr3")

        it "should create properties of subclass", ->
            expectFunction(ExtendingModel, "attr3")

        it "should set super-class properties in sub-class", ->
            model = new ExtendingModel()
            model.attr1("test")
            expect(model._attr1).to.equal("test")

        it "should get super-class properties in sub-class", ->
            model = new ExtendingModel()
            model._attr1 = "test"
            expect(model.attr1()).to.equal("test")

        describe 'clone', ->

            it "should clone attribute values", ->
                model = new ExtendingModel()
                model.attr1 "testvalue1"
                model.attr2 "testvalue2"
                model.attr3 1337
                cloneModel = model.clone()

                expect(cloneModel.attr1()).to.equal "testvalue1"
                expect(cloneModel.attr2()).to.equal "testvalue2"
                expect(cloneModel.attr3()).to.equal 1337

            it 'should be independent of original instance', ->
                model = new ExtendingModel()
                cloneModel = model.clone()

                cloneModel.attr3('newtestvalue')
                expect(cloneModel.attr3()).to.not.equal model.attr3()

            it.skip 'should handle null and undefined value', ->
                model = new ExtendingModel()
                model.attr1 null
                console.log model._attr1
                model.attr2 undefined
                cloneModel = model.clone()

                expect(cloneModel.attr1()).to.be.null
                expect(cloneModel.attr1()).to.be.undefined

            it 'should handle simple arrays', ->
                # TODO

            it "should deep clone and not keep a reference to the original properties", ->
                model = new ExtendingModel()
                objectToClone =
                    nest:
                        first: 1
                        second: 2
                    notnest: 'animal'

                model.attr3 objectToClone

                cloneModel = model.clone()

                expect(cloneModel.attr3()).to.deep.equal objectToClone
                expect(cloneModel.attr3()).to.not.equal objectToClone

            it.skip "should return an instance of the model class", ->
                # TODO

            it.skip "should call default constructor", ->
                # TODO


    describe "PostSetAction", ->

        spy = sinon.spy()
        PostSetAction(SimpleModel, spy)
        PostSetAction(ExtendingModel, spy)

        beforeEach ->
            spy.reset()

        it "should call the post set action", ->
            model = new SimpleModel()
            model.setAttr1(1)
            expect(model._attr1).to.equal 1
            expect(spy.calledWith("attr1", 1, null)).to.be.true
            model.setAttr2(2)
            expect(model._attr2).to.equal 2
            expect(spy.calledWith("attr2", 2, null)).to.be.true
            model.setAttr2(3)
            expect(spy.calledWith("attr2", 3, 2)).to.be.true

        it "should call the post set action in sub class", ->
            model = new ExtendingModel()
            model.setAttr1(1)
            expect(model._attr1).to.equal 1
            expect(spy.calledWith("attr1", 1, null)).to.be.true
            model.setAttr3(2)
            expect(model._attr3).to.equal 2
            expect(spy.calledWith("attr3", 2, null)).to.be.true
            model.setAttr3(3)
            expect(spy.calledWith("attr3", 3, 2)).to.be.true
