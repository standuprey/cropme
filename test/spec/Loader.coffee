'use strict'

describe 'Factory: Loader', ->

	BaseCollection = null
	config = null
	$httpBackend = null

	beforeEach module 'llServices'

	beforeEach inject ($injector) ->
		config = $injector.get "config"
		Persist = $injector.get "Persist"
		$httpBackend = $injector.get "$httpBackend"
		Persist.reset()

	it 'should be make the collection available once then\'d', inject ($injector, $rootScope, Loader, GarmentCollection) ->
		initCollection = (collectionNames) ->
			response = [{name: "First #{collectionNames[0]}"}, {name: "Second #{collectionNames[0]}"}]
			$httpBackend.whenGET("#{config.apiUrl}/#{collectionNames[1]}").respond 200, JSON.stringify(response)
			$httpBackend.whenGET("#{config.apiUrl}/counters/#{collectionNames[1]}").respond 200, "2"
			collection = $injector.get "#{collectionNames[0]}Collection"

		allCollectionNames = [["Garment", "garments"], ["Category", "categories"], ["Color", "colors"]]
		initCollection(collectionNames)  for collectionNames in allCollectionNames
		$httpBackend.whenGET("#{config.apiUrl}/styles").respond 500
		$httpBackend.whenGET("#{config.apiUrl}/counters/styles").respond 200, "2"
		StyleCollection = $injector.get "StyleCollection"
		$httpBackend.whenGET("#{config.apiUrl}/counters/designers").respond 500
		DesignerCollection = $injector.get "DesignerCollection"
		
		isInit = false
		Loader.load().then ->
			expect(GarmentCollection.all().length).toBe 2
			expect(DesignerCollection.all().length).toBe 0
			expect(StyleCollection.all().length).toBe 0
			isInit = true
		expect(isInit).toBe false
		expect(Loader._promises.length).toBe 5
		expect(-> GarmentCollection.all()).toThrow()

		$httpBackend.flush()
		$rootScope.$apply()

		expect(isInit).toBe true
