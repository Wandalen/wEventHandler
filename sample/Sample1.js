( function _Sample_s_( ) {

'use strict';

// dependencies

if( typeof module !== 'undefined' )
{

  require( 'wEventHandler' );

}

// constructor

var _ = wTools;
var Parent = null;
var Self = function Sample( o )
{
  if( !( this instanceof Self ) )
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

// --
// methods
// --

var init = function()
{
  var self = this;

}

//

var event1 = function()
{
  var self = this;

  self.eventHandle( 'event1' );

}

// --
// proto
// --

var Proto =
{

  init : init,
  event1 : event1,
  constructor : Self,

};

_.protoMake
({
  constructor : Self,
  parent : Parent,
  extend : Proto,
});

wEventHandler.mixin( Self );

_global_.Sample = Self;

// make an instance

var sample = new Sample;

sample.on( 'event1',function( e ) {
  console.log( e )
});

sample.on( 'event2',function( e ) {
  console.log( e )
});

sample.on( 'finit',function( e ) {
  console.log( e )
});

sample.event1();
sample.eventHandle( 'event2' );
sample.finit();

})();
