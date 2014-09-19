'use strict'

describe 'Factory: BaseCollection', ->

	BaseCollection = null
	prefix = null
	config = null
	$httpBackend = null

	beforeEach module 'llServices'

	beforeEach inject ($injector, $rootScope) ->
		config = $injector.get "config"
		Persist = $injector.get "Persist"
		Persist.reset()
		prefix = Persist._prefix
		$httpBackend = $injector.get "$httpBackend"
		$httpBackend.whenGET("#{config.apiUrl}/bases").respond 200, "[{\"size\": 1}, {\"size\": 2}]"
		$httpBackend.whenGET("#{config.apiUrl}/counters/bases").respond 200, "1"
		BaseCollection = $injector.get("BaseCollection").extend {}
		$httpBackend.flush()
		$rootScope.$apply()

	it 'should be able to generate a cid which looks like a uuid', ->
		model = new BaseCollection.Model
		expect(model.cid.length).toBe 36
		expect(model.cid).toMatch /........_...._4..._y..._............/

	it 'should be able to create an instance with a literal and copy the cid', ->
		model = new BaseCollection.Model
		model2 = new BaseCollection.Model model
		expect(model2.cid).toBe model.cid

	it 'should have the name "bases"', ->
		expect(BaseCollection.name).toBe "bases"

	it 'should extend BaseCollection', ->
		expect(BaseCollection.extend {}).toEqual BaseCollection
		newBaseCollection = BaseCollection.extend { name: "newBaseCollection" }
		expect(newBaseCollection.name).toBe "newBaseCollection"

	it 'should get an empty array when calling all() on an empty BaseCollection', ->
		all = BaseCollection.all()
		expect(all.length).toBe 2
		expect(all[0].size).toBe 1
		expect(all[1].size).toBe 2

	it ':findOne should a model by its cid, with or without specifying the field as being "cid"', ->
		model = BaseCollection.all()[0]
		expect(BaseCollection.findOne(model.cid).cid).toBe model.cid
		expect(BaseCollection.findOne(model.cid, "cid").cid).toBe model.cid

	it ':findOne should return null if no value is given', ->
		expect(BaseCollection.findOne(null)).toBeNull()

	it ':findOne should return null if value not found', ->
		expect(BaseCollection.findOne(123)).toBeNull()

	it ':find should find a model by its cid, with or without specifying the field as being "cid"', ->
		model = BaseCollection.all()[0]
		expect(BaseCollection.find(model.cid, "cid")[0].cid).toBe model.cid

	it ':find should return [] if no value or no field is given', ->
		expect(BaseCollection.find().length).toBe 0
		expect(BaseCollection.find(123).length).toBe 0

	it ':find should return [] if value not found', ->
		expect(BaseCollection.find(123, "cid").length).toBe 0
