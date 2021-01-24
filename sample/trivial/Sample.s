( function _Sample_s_( )
{

'use strict';

// dependencies

if( typeof module !== 'undefined' )
require( 'wEventHandler' );

// constructor

let _ = wTools;
let Parent = null;
let Self = Sample;
function Sample( o )
{
  return _.workpiece.construct( Self, this, arguments );
}

// --
// methods
// --

function init()
{
  var self = this;

  console.log( 'init' );

}

//

function event1()
{
  var self = this;

  self.eventGive( 'event1' );

}

// --
// proto
// --

var Events =
{
  event1 : 'event1',
  event2 : 'event2',
}

var Proto =
{

  init,
  event1,
  Events,

};

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

wEventHandler.mixin( Self );
_global_.Sample = Self;

// make an instance

var sample = new Self;

sample.on( 'event1', function( e )
{
  console.log( 'event1' );
});

sample.on( 'event2', function( e )
{
  console.log( 'event2' );
});

sample.on( 'finit', function( e )
{
  console.log( 'finit' );
});

sample.event1();
sample.eventGive( 'event2' );
sample.off( 'event1' );
sample.off( 'event2' );
sample.finit();

})();
