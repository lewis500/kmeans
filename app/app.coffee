angular = require 'angular'
d3 = require 'd3'
_ = require 'lodash'

euclid = (a,b)->
	((a.x-b.x)**2 + (a.y-b.y)**2)**0.5

class Centroid
	constructor: (@x,@y)->
		_.assign this,
			id: _.uniqueId()
			dots: []

	addDot:(dot)->
		@dots.push dot

	clear: ->
		@dots = []

	move: ->
		#calculate average x and y coordinate
		[sumX,sumY] = [0,0]
		@dots.forEach (d)->
			sumX += d.x
			sumY += d.y
		l = @dots.length
		if l > 0
			@x = sumX / l
			@y = sumY / l
		else
			#if no points, then just put it somewhere else
			@x = Math.random()*100
			@y = Math.random()*100

class Dot
	constructor: (@x,@y)->
		_.assign this,
			centroid: null
			d: 1000
			id: _.uniqueId()

	update: (@d,@centroid) ->

class Ctrl
	constructor: (@scope, el)->
		@makeDots()
		@makeCentroids @dots

	makeCentroids: (dots)->
		#implements k++ algorithm
		@centroids = _.sample dots, 4
			.map (centroid)=>
				distances = dots.map (dot) ->
					d = euclid dot,centroid
				ss = distances.reduce (a,b)->
					a + b**2
				q = 0
				intervals = distances.map (d)->
					q += ((d**2)/ss)
				console.log intervals
				draw = Math.random()
				i = _.findLastIndex intervals, (d)->
					d < draw
				c = dots[i]
				new Centroid c.x, c.y

	gen: (mean,std)->
		res = d3.random.normal(mean,std)()
		Math.max Math.min(res, 100), 0

	makeDots:->
		@dots = []

		_.range 0,30
			.forEach =>
				@dots.push new Dot @gen(20,5), @gen(20,8)

		_.range 0,100
			.forEach =>
				@dots.push new Dot @gen(70,10), @gen(70,10)

		_.range 0,100
			.forEach =>
				@dots.push new Dot @gen(80,7), @gen(15,3)

		_.range 0,75
			.forEach =>
				@dots.push new Dot @gen(40,7), @gen(80,3)

	update: ->
		_.invoke @centroids,'clear'

		@dots.forEach (dot)=>
			_.chain @centroids
				.map  (centroid)->
					res = 
						distance: euclid dot,centroid
						centroid: centroid
				.min 'distance'
				.value()
				.centroid.addDot dot
				
		_.invoke @centroids,'move'

		@scope.$evalAsync()

	vor: d3.geom.voronoi()
		.x (d)-> d.x
		.y (d)-> d.y
		.clipExtent [[0,0], [100,100]]

	vorPaths: ->
		data = @vor @centroids
		res = data.map (d)->
			'M' + d.join('L') + 'Z'


visDer = ->
	directive = 
		scope: {}
		controllerAs: 'vm'
		templateUrl: './dist/vis.html'
		controller: ['$scope', '$element', Ctrl]

angular.module 'mainApp' , []
	.directive 'visDer', visDer

