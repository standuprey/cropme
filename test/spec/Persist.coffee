"use strict"

describe "Factory: Persist", ->

	Persist = null
	Storage = null
	prefix = null
	config = null
	$httpBackend = null

	# Sample class
	class Human
		size: 0
		name: ""
		age: 0
		constructor: (literal) ->
			@size = literal.size
			@age = literal.age
			@name = literal.name
		sayHi: -> "Hi! My name is #{@name} and I am #{@age} old."

	# create a human as persistable
	createHuman = ->
		humans = Persist.get "humans", Human
		humans.push new Human
			size: 177
			name: "Yvette"
			age: 66

	beforeEach module "llServices"

	beforeEach inject ($injector, $rootScope) ->
		Persist = $injector.get "Persist"
		Storage = $injector.get "Storage"
		config = $injector.get "config"
		$httpBackend = $injector.get "$httpBackend"
		$httpBackend.whenGET("#{config.apiUrl}/humans").respond 200, "[{\"size\": 1}, {\"size\": 2}]"
		$httpBackend.whenGET("#{config.apiUrl}/counters/humans").respond 200, "1"
		$httpBackend.whenGET("#{config.apiUrl}/humans2").respond 500
		$httpBackend.whenGET("#{config.apiUrl}/counters/humans2").respond 200, "1"
		$httpBackend.whenGET("#{config.apiUrl}/counters/humanoids").respond 500
		Persist.reset()
		prefix = Persist._prefix

	afterEach ->
		$httpBackend.verifyNoOutstandingExpectation()
		$httpBackend.verifyNoOutstandingRequest()

	it "should create an empty object when calling getObject", ->
		config = Persist.getObject "config"
		expect(JSON.stringify(config)).toBe "{}"

	it "should return the updated getObject", ->
		config = Persist.getObject "config"
		config.size = 10
		config = Persist.getObject "config"
		expect(config).toEqual {size:10}

	it "should not allow to call getObject refering to a collection", inject ($rootScope) ->
		Persist.initCollection "humans", Human
		$httpBackend.expectGET "#{config.apiUrl}/humans"
		$httpBackend.flush()
		$rootScope.$apply()
		expect(-> Persist.getObject("humans")).toThrow()

	it "should find the object in the Storage", inject ->
		Storage["#{prefix}_config"] = "{\"size\": 10}"
		config = Persist.getObject "config"
		expect(config).toEqual { size: 10 }

	it "should get the local empty collection", inject ($q, $rootScope) ->
		h = null
		deferred = $q.defer()
		Persist._getLocalCollection(deferred, "humans", Human)
		deferred.promise.then (col) -> h = col
		$rootScope.$apply()
		expect(h).toEqual []

	it "should get the local collection with value", inject ($q, $rootScope) ->
		h = null
		Storage["#{prefix}_humans"] = "[{\"size\": 1}, {\"size\": 2}]"
		deferred = $q.defer()
		Persist._getLocalCollection(deferred, "humans", Human)
		deferred.promise.then (col) -> h = col
		$rootScope.$apply()
		expect(h.length).toBe 2
		expect(h[0].size).toBe 1
		expect(h[1].size).toBe 2

	it "should call the collection's endpoint and return a result", inject ($q, $rootScope) ->
		h = null
		deferred = $q.defer()
		Persist._fetchCollection(deferred, "humans", Human)
		deferred.promise.then (col) -> h = col
		$httpBackend.expectGET "#{config.apiUrl}/humans"
		$httpBackend.flush()
		$rootScope.$apply()
		expect(h.length).toBe 2
		expect(h[0].size).toBe 1
		expect(h[1].size).toBe 2

	it "should init an empty array when initCollection is called with a Model", inject ($rootScope) ->
		Persist.initCollection "humans", Human
		$httpBackend.expectGET "#{config.apiUrl}/humans"
		$httpBackend.flush()
		$rootScope.$apply()
		expect(Persist.getCollection("humans").length).toBe 2
		expect(Persist.getCollection("humans")[0].size).toBe 1
		expect(Persist.getCollection("humans")[1].size).toBe 2

	it "should get value from Storage if the counter is in sync", inject ($rootScope) ->
		Storage["#{prefix}_counter_humans"] = "1"
		Storage["#{prefix}_humans"] = "[{\"size\": 123}]"
		Persist.initCollection "humans", Human
		$httpBackend.flush()
		$rootScope.$apply()
		expect(Persist.getCollection("humans").length).toBe 1
		expect(Persist.getCollection("humans")[0].size).toBe 123

	it "should call the collection's endpoint and get the local collection if the call status is an error", inject ($q, $rootScope) ->
		h = null
		localStorage["#{prefix}_humanoids"] = "[{\"size\": 1}, {\"size\": 2}]"
		deferred = $q.defer()
		Persist.initCollection("humanoids", Human).then (col) -> h = col
		$httpBackend.flush()
		$rootScope.$apply()
		expect(h.length).toBe 2
		expect(h[0].size).toBe 1
		expect(h[1].size).toBe 2
		h = null
		localStorage["#{prefix}_humans2"] = "[{\"size\": 1}, {\"size\": 2}]"
		deferred = $q.defer()
		Persist.initCollection("humans2", Human).then (col) -> h = col
		$httpBackend.flush()
		$rootScope.$apply()
		expect(h.length).toBe 2
		expect(h[0].size).toBe 1
		expect(h[1].size).toBe 2

	it "should not be able to save a collection", inject ($rootScope) ->
		Persist.initCollection "humans", Human
		$httpBackend.expectGET "#{config.apiUrl}/humans"
		$httpBackend.flush()
		$rootScope.$apply()
		expect(-> Persist.save("humans")).toThrow()

	it "should not be able to save an unknown object", inject ($rootScope) ->
		expect(-> Persist.save({humans: 0})).toThrow()

	it "should be able to save a persisted object", inject ($rootScope) ->
		config = Persist.getObject "config"
		config.size = 10
		expect(Persist.save("config")).toEqual { size: 10 }
		expect(Storage["#{prefix}_config"]).toBe "{\"size\":10}"

	it "should reset all values", inject ($rootScope) ->
		Storage["something"] = "something"
		Persist.initCollection "humans", Human
		$httpBackend.expectGET "#{config.apiUrl}/humans"
		$httpBackend.flush()
		$rootScope.$apply()
		expect(Persist.getCollection("humans").length).toBe 2
		Persist.reset()
		expect(-> Persist.getCollection("humans")).toThrow()
		expect(Storage["something"]).toBe "something"
