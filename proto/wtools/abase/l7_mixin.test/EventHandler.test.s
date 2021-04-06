( function _EventHandler_test_()
{

'use strict';

if( typeof module !== 'undefined' )
{

  const _ = require( '../../../node_modules/Tools' );

  _.include( 'wTesting' );
  _.include( 'wConsequence' );

  require( '../l7_mixin/EventHandler.s' );

}

const _global = _global_;
const _ = _global_.wTools;

// --
// test
// --

function basic( test )
{
  var self = this;

  /* */

  function Entity1(){ this.init() };
  _.EventHandler.mixin( Entity1 );
  Entity1.prototype.Events =
  {
    init : 'init',
    until : 'until',
    event1 : 'event1',
    event2 : 'event2',
    event3 : 'event3',
    event33 : 'event33',
  };

  function Entity2(){ this.init() };
  _.EventHandler.mixin( Entity2 );
  Entity2.prototype.Events =
  {
    init : 'init',
    until : 'until',
    event1 : 'event1',
    event2 : 'event2',
    event3 : 'event3',
    event33 : 'event33',
  };

  function onEvent1( e ){ return entity1[ e.kind ] = ( entity1[ e.kind ] || 0 ) + 1; };
  function onEvent2( e ){ return entity1[ e.kind ] = ( entity1[ e.kind ] || 0 ) + 1; };
  function onEvent3( e ){ return entity1[ e.kind ] = ( entity1[ e.kind ] || 0 ) + 1; };

  /* make two entities */

  var entity1 = new Entity1();
  var entity2 = new Entity2();

  /* */

  test.case = 'eventHandlerAppend';

  entity1.on( 'event1', onEvent1 );
  entity1.eventHandlerAppend( 'event2', onEvent2 );
  entity1.on( 'event3', 'owner', onEvent3 );

  test.identical( entity1._eventHandlerDescriptorByHandler( onEvent1 ).onHandle, onEvent1 );
  test.identical( entity1._eventHandlerDescriptorByHandler( onEvent3 ).owner, 'owner' );
  test.identical( entity1._eventHandlerDescriptorByKindAndOwner( 'event3', 'owner' ).onHandle, onEvent3 );
  test.identical( entity1._eventHandlerDescriptorByKindAndOwner( 'event3', 'owner' ).kind, 'event3' );
  test.identical( entity1._eventHandlerDescriptorByKindAndOwner( 'event3', 'owner' ).owner, 'owner' );
  test.identical( entity1._eventHandlerDescriptorByKindAndHandler( 'event3', onEvent3 ).owner, 'owner' );

  /* */

  test.identical( entity1.eventGive( 'event1' ), [ 1 ] );
  test.identical( entity1[ 'event1' ], 1 );

  test.identical( entity1.eventGive( 'event2' ), [ 1 ] );
  test.identical( entity1.eventGive( 'event2' ), [ 2 ] );
  test.identical( entity1[ 'event2' ], 2 );

  test.identical( entity1.eventGive( 'event3' ), [ 1 ] );
  test.identical( entity1.eventGive( 'event3' ), [ 2 ] );
  test.identical( entity1[ 'event3' ], 2 );

  /* */

  test.case = 'eventHandleUntil';

  function onUntil0( e ){ entity1[ e.kind ] = ( entity1[ e.kind ] || 0 ) + 1; return 0; };
  function onUntil1( e ){ entity1[ e.kind ] = ( entity1[ e.kind ] || 0 ) + 1; return 1; };
  function onUntil2( e ){ entity1[ e.kind ] = ( entity1[ e.kind ] || 0 ) + 1; return 2; };
  function onUntil3( e ){ entity1[ e.kind ] = ( entity1[ e.kind ] || 0 ) + 1; return 3; };

  entity1.on( 'until', onUntil0 );
  entity1.on( 'until', onUntil1 );
  entity1.on( 'until', onUntil2 );
  entity1.on( 'until', 'onUntil3_owner', onUntil3 );

  test.identical( entity1.eventHandleUntil( 'until', 0 ), 0 );
  test.identical( entity1[ 'until' ], 1 );

  test.identical( entity1.eventHandleUntil( 'until', 1 ), 1 );
  test.identical( entity1[ 'until' ], 3 );

  test.identical( entity1.eventHandleUntil( 'until', 2 ), 2 );
  test.identical( entity1[ 'until' ], 6 );

  /* */

  test.case = 'eventHandlerRemove';

  entity1.eventHandlerRemove( 'until', onUntil0 );
  test.identical( entity1.eventHandleUntil( 'until', 0 ), [ 1, 2, 3 ] );
  test.identical( entity1[ 'until' ], 9 );

  entity1.eventHandlerRemove( onUntil1 );
  test.identical( entity1.eventHandleUntil( 'until', 1 ), undefined );
  test.identical( entity1[ 'until' ], 11 );

  entity1.eventHandlerRemove( 'until' );
  test.identical( entity1.eventHandleUntil( 'until', 1 ), undefined );
  test.identical( entity1[ 'until' ], 11 );

  test.identical( entity1.eventGive( 'event3' ), [ 3 ] );
  test.identical( entity1[ 'event3' ], 3 );
  entity1._eventHandlerRemove({ owner : 'owner' });
  test.identical( entity1.eventHandleUntil( 'until', 1 ), undefined );
  test.identical( entity1.eventGive( 'event3' ), [] );
  test.identical( entity1[ 'event3' ], 3 );

  test.identical( entity1.eventGive( 'event1' ), [ 2 ] );
  test.identical( entity1[ 'event1' ], 2 );

  /* */

  test.case = 'eventProxyTo';

  var entity1 = new Entity1();
  var entity2 = new Entity2();

  entity1.on( 'event1', 'owner', onEvent1 );
  entity1.on( 'event1', 'owner', onEvent1 );
  entity1.on( 'event1', 'owner', onEvent1 );
  entity1.on( 'event1', 'owner', onEvent1 );
  entity1.on( 'event1', 'owner', onEvent1 );
  entity1.on( 'event1', 'owner', onEvent2 );
  entity1.on( 'event1', 'owner3', onEvent3 );

  entity1.on( 'event33', onEvent3 );
  entity1.on( 'event33', onEvent3 );
  entity1.eventProxyFrom( entity2,
    {
      'event1' : 'event1',
      'event3' : 'event33',
    });

  test.identical( entity1.eventGive( 'event1' ), [ 1, 2 ] );
  test.identical( entity1.eventGive( 'event2' ), [] );
  test.identical( entity1.eventGive( 'event3' ), [] );
  test.identical( entity1.eventGive( 'event33' ), [ 1, 2 ] );

  test.identical( entity2.eventGive( 'event1' ), [ 3, 4 ] );
  test.identical( entity2.eventGive( 'event2' ), [] );
  test.identical( entity2.eventGive( 'event3' ), [ 3, 4 ] );
  test.identical( entity2.eventGive( 'event33' ), [] );

  test.identical( entity1[ 'event1' ], 4 );
  test.identical( entity1[ 'event2' ], undefined );
  test.identical( entity1[ 'event3' ], undefined );
  test.identical( entity1[ 'event33' ], 4 );

  /* */

  test.case = 'eventHandlerRemoveByKindAndOwner';

  test.identical( entity1.eventGive( 'event1' ), [ 5, 6 ] );
  test.identical( entity1[ 'event1' ], 6 );
  try
  {
    entity1.eventHandlerRemove( onEvent1 );
    test.identical( 'error had to be throwen because no such handler', false );
  }
  catch( err )
  {
    test.identical( 1, 1 );
  }

  test.identical( entity1.eventGive( 'event1' ), [ 7, 8 ] );
  test.identical( entity1[ 'event1' ], 8 );
  entity1.eventHandlerRemoveByKindAndOwner( 'event1', 'owner' );
  test.identical( entity1.eventGive( 'event1' ), [ 9 ] );
  test.identical( entity1[ 'event1' ], 9 );

  test.identical( entity1.eventGive( 'event33' ), [ 5, 6 ] );
  test.identical( entity1[ 'event33' ], 6 );
  entity1.eventHandlerRemove();
  test.identical( entity1.eventGive( 'event33' ), [] );
  test.identical( entity1[ 'event33' ], 6 );
  test.identical( entity1.eventGive( 'event1' ), [] );
  test.identical( entity1[ 'event1' ], 9 );
}

//

function once( test )
{
  var self = this;

  /* prepare objects */

  function Entity1()
  {
    this.init()
  }
  _.EventHandler.mixin( Entity1 );
  Entity1.prototype.Events =
  {
    init : 'init',
    event : 'event',
    event2 : 'event2',
  };

  function Entity2()
  {
    this.init()
  }
  _.EventHandler.mixin( Entity2 );
  Entity2.prototype.Events =
  {
    init : 'init',
    event : 'event',
    event2 : 'event2',
  };

  /* test */

  test.open( 'without owner' );

  test.case = 'no events handlers in entity';
  var entity1 = new Entity1();
  var result = [];
  var onEvent = () => result.push( result.length )
  var onEvent2 = () => result.push( -1 * result.length )
  entity1.eventGive( 'event' );
  test.identical( result, [] );
  entity1.eventGive( 'event2' );
  test.identical( result, [] );

  /* */

  test.case = 'single events handler in entity';
  var entity1 = new Entity1();
  var result = [];
  var onEvent = () => result.push( result.length )
  var onEvent2 = () => result.push( -1 * result.length )
  entity1.once( 'event', onEvent );
  entity1.eventGive( 'event' );
  test.identical( result, [ 0 ] );
  entity1.eventGive( 'event2' );
  test.identical( result, [ 0 ] );

  /* */

  test.case = 'single events handler in entity, a few events';
  var entity1 = new Entity1();
  var result = [];
  var onEvent = () => result.push( result.length )
  var onEvent2 = () => result.push( -1 * result.length )
  entity1.once( 'event', onEvent );
  entity1.eventGive( 'event' );
  entity1.eventGive( 'event' );
  test.identical( result, [ 0 ] );
  entity1.eventGive( 'event2' );
  test.identical( result, [ 0 ] );

  /* */

  test.case = 'several entities, the second gives events';
  var entity1 = new Entity1();
  var entity2 = new Entity2();
  var result = [];
  var onEvent = () => result.push( result.length )
  var onEvent2 = () => result.push( -1 * result.length )
  entity1.once( 'event', onEvent );
  entity1.once( 'event2', onEvent2 );
  entity2.eventGive( 'event' );
  entity2.eventGive( 'event' );
  test.identical( result, [] );
  entity2.eventGive( 'event2' );
  entity2.eventGive( 'event2' );
  test.identical( result, [] );

  test.close( 'without owner' );

  /* - */

  test.open( 'with owner' );

  test.case = 'single events handler in entity';
  var entity1 = new Entity1();
  var result = [];
  var onEvent = () => result.push( result.length )
  var onEvent2 = () => result.push( -1 * result.length )
  entity1.once( 'event', 'owner', onEvent );

  var descriptor = entity1._eventHandlerDescriptorsByKind( 'event' )[ 0 ];
  test.identical( descriptor.owner, 'owner' );
  test.identical( descriptor.onHandle, onEvent );
  entity1.eventGive( 'event' );
  test.identical( result, [ 0 ] );
  entity1.eventGive( 'event2' );
  test.identical( result, [ 0 ] );

  /* */

  test.case = 'single events handler in entity, a few events';
  var entity1 = new Entity1();
  var result = [];
  var onEvent = () => result.push( result.length )
  var onEvent2 = () => result.push( -1 * result.length )
  entity1.once( 'event', 'owner', onEvent );

  var descriptor = entity1._eventHandlerDescriptorsByKind( 'event' )[ 0 ];
  test.identical( descriptor.owner, 'owner' );
  test.identical( descriptor.onHandle, onEvent );
  entity1.eventGive( 'event' );
  entity1.eventGive( 'event' );
  test.identical( result, [ 0 ] );
  entity1.eventGive( 'event2' );
  test.identical( result, [ 0 ] );

  /* */

  test.case = 'several entities, the second gives events';
  var entity1 = new Entity1();
  var entity2 = new Entity2();
  var result = [];
  var onEvent = () => result.push( result.length )
  var onEvent2 = () => result.push( -1 * result.length )
  entity1.once( 'event', 'owner', onEvent );
  entity1.once( 'event2', 'owner', onEvent2 );
  entity2.once( 'event', () => {} );

  var descriptor = entity1._eventHandlerDescriptorsByKind( 'event' )[ 0 ];
  test.identical( descriptor.owner, 'owner' );
  test.identical( descriptor.onHandle, onEvent );
  var descriptor = entity2._eventHandlerDescriptorsByKind( 'event' )[ 0 ];
  test.identical( descriptor.owner, undefined );
  test.true( _.routineIs( descriptor.onHandle ) );
  entity2.eventGive( 'event' );
  entity2.eventGive( 'event' );
  test.identical( result, [] );
  entity2.eventGive( 'event2' );
  entity2.eventGive( 'event2' );
  test.identical( result, [] );

  test.close( 'with owner' );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'give not known event';
  var entity1 = new Entity1();
  test.shouldThrowErrorSync( () => entity1.eventGive( 'notKnown' ) );
}

//

function eventWaitFor( test )
{
  function Entity1(){ this.init() };
  _.EventHandler.mixin( Entity1 );
  Entity1.prototype.Events =
  {
    init : 'init',
    event1 : 'event1',
  };

  test.case = 'several calls, returned consequence must give message only once,event given several times'

  var entity1 = new Entity1();
  var cons = [];

  cons.push( entity1.eventWaitFor( 'event1' ) );
  cons.push( entity1.eventWaitFor( 'event1' ) );
  cons.push( entity1.eventWaitFor( 'event1' ) );

  entity1.eventGive( 'event1' );
  entity1.eventGive( 'event1' );
  entity1.eventGive( 'event1' );

  var con  = _.Consequence().take( null );
  con.andKeep( cons );

  let timeOut = _.time.outError( 3000 ).catch( ( err ) =>
  {
    throw _.errAttend( err );
  });

  // con.orKeepingSplit( _.time.outError( 3000 ).catch( ( err ) =>
  // .catch( ( err ) =>
  // {
  //   throw _.errAttend( err );
  // }));

  con = _.Consequence.Or( con, timeOut )

  con.ifNoErrorThen( ( arg ) =>
  {
    for( var i = 0; i < cons.length; i++ )
    test.returnsSingleResource( cons[ i ] );
    return null;
  })

  return con;
}

// --
// declare
// --

const Proto =
{

  name : 'Tools.EventHandlerMixin',
  silencing : 1,

  tests :
  {

    basic,
    once,
    eventWaitFor,

  },

}

//

const Self = wTestSuite( Proto );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

} )( );
