( function _EventHandler_s_() {

'use strict';

/**
  @module Tools/base/EventHandler - Mixin adds events dispatching mechanism to your class. EventHandler provides methods to bind/unbind handler of an event, to handle a specific event only once, to associate an event with a namespace what later make possible to unbind handler of event with help of namespace. EventHandler allows redirecting events to/from another instance. Unlike alternative implementation of the concept, EventHandler is strict by default and force developer to explicitly declare / bind / unbind all events supported by object. Use it to add events dispatching mechanism to your classes and avoid accumulation of technical dept and potential errors.
*/

/**
 * @file X.s.
 */

/*

- implement tracking of event kinds !!!
- remove deprecated features !!!
- refactor !!!

*/

if( typeof module !== 'undefined' )
{

  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    let toolsPath = '../../../dwtools/Base.s';
    let toolsExternal = 0;
    try
    {
      toolsPath = require.resolve( toolsPath );
    }
    catch( err )
    {
      toolsExternal = 1;
      require( 'wTools' );
    }
    if( !toolsExternal )
    require( toolsPath );
  }

  var _ = _global_.wTools;

  _.include( 'wProto' );

}

var _global = _global_;
var _ = _global_.wTools;
var _ObjectHasOwnProperty = Object.hasOwnProperty;

//

/**
 * @class wEventHandler
 */

var _global = _global_;
var _ = _global_.wTools;
var Parent = null;
var Self = function wEventHandler( o )
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'EventHandler';

//

/**
 * Mixin this methods into prototype of another object.
 * @param {object} dstPrototype - prototype of another object.
 * @method copy
 * @memberof wEventHandler#
 */

function onMixin( mixinDescriptor, dstClass )
{
  var dstPrototype = dstClass.prototype;

  _.mixinApply( this, dstPrototype );

  _.assert( _.objectIs( dstPrototype.Restricts._eventHandler ) );
  _.assert( arguments.length === 2, 'expects exactly two arguments' );
  _.assert( _.routineIs( dstClass ) );
  _.assert( _.objectIs( dstPrototype.Events ) );
  _.assert( _.strIs( dstPrototype.Events.init ) );
  _.assert( _.strIs( dstPrototype.Events.finit ) );

  _.accessorForbidOwns( dstPrototype, '_eventHandlers' );

}

// --
// Functors
// --

/**
 * Functors to produce init.
 * @param { routine } original - original method.
 * @method init
 * @memberof wEventHandler#
 */

function init( original )
{

  return function initEventHandler()
  {
    var self = this;

    self._eventHandlerInit();

    var result = original ? original.apply( self,arguments ) : undefined;

    self.eventGive( 'init' );

    return result;
  }

}

//

/**
 * Functors to produce finit.
 * @param { routine } original - original method.
 * @method finit
 * @memberof wEventHandler#
 */

function finit( original )
{

  return function finitEventHandler()
  {
    var self = this;

    self.eventGive( 'finit' );

    if( original )
    var result = original ? original.apply( self,arguments ) : undefined;

    self._eventHandlerFinit();

    return result;
  }

}

// --
// register
// --

function _eventHandlerInit()
{
  var self = this;

  _.assert( !self._eventHandler,'EventHandler.init already done for ',self.nickName );
  _.assert( self instanceof self.constructor );

  if( !self._eventHandler )
  self._eventHandler = Object.create( null );

  if( !self._eventHandler.descriptors )
  self._eventHandler.descriptors = Object.create( null );

}

//

function _eventHandlerFinit()
{
  var self = this;

  if( Config.debug || !self.strictEventHandling )
  {

    var handlers = self._eventHandler.descriptors;
    if( !handlers )
    return;

    for( var h in handlers )
    {
      if( !handlers[ h ] || handlers[ h ].length === 0 )
      continue;
      if( h === 'finit' )
      continue;
      var err = 'Finited instance has bound handler(s), but should not' + h + ':\n' + _.toStr( handlers[ h ],{ levels : 2, } );
      console.error( err.toString() + '\n' + err.stack );
      console.error( handlers[ h ][ 0 ].onHandle );
      console.error( self.eventReport() );
      debugger;
      throw _.err( err );
    }

  }

  self.eventHandlerRemove();
}

//

function eventReport()
{
  var self = this;
  var result = 'Event Map of ' + ( self.nickName || 'an instance' ) + ':\n';

  var handlers = self._eventHandler.descriptors || {};
  for( var h in handlers )
  {
    var handlerArray = handlers[ h ];
    if( !handlerArray || handlerArray.length === 0 )
    continue;
    var onHandle = handlerArray.map( ( e ) => _.toStr( e.onHandle ) );
    result += h + ' : ' + onHandle.join( ', ' ) + '\n';
  }

  for( var h in self.Events )
  {
    var handlerArray = handlers[ h ];
    if( !handlerArray || handlerArray.length === 0 )
    {
      result += h + ' : ' + '-' + '\n';
    }
  }

  return result;
}

//

function eventHandlerPrepend( kind, onHandle )
{
  var self = this;
  var owner;

  _.assert( arguments.length === 2 || arguments.length === 3,'eventHandlerAppend:','expects "kind" and "onHandle" as arguments' );

  if( arguments.length === 3 )
  {
    owner = arguments[ 1 ];
    onHandle = arguments[ 2 ];
  }

  var descriptor =
  {
    kind : kind,
    onHandle : onHandle,
    owner : owner,
    appending : 0,
  }

  self._eventHandlerRegister( descriptor );

  return self;
}

//

function eventHandlerAppend( kind, onHandle )
{
  var self = this;
  var owner;

  _.assert( arguments.length === 2 || arguments.length === 3,'eventHandlerAppend:','expects "kind" and "onHandle" as arguments' );

  if( arguments.length === 3 )
  {
    owner = arguments[ 1 ];
    onHandle = arguments[ 2 ];
  }

  var descriptor =
  {
    kind : kind,
    onHandle : onHandle,
    owner : owner,
    appending : 1,
  }

  self._eventHandlerRegister( descriptor );

  return self;
}

//

function eventHandlerRegisterProvisional( kind, onHandle )
{
  var self = this;
  var owner;

  _.assert( arguments.length === 2 || arguments.length === 3,'eventHandlerRegisterProvisional:','expects "kind" and "onHandle" as arguments' );

  if( arguments.length === 3 )
  {
    owner = arguments[ 1 ];
    onHandle = arguments[ 2 ];
  }

  var descriptor =
  {
    kind : kind,
    onHandle : onHandle,
    owner : owner,
    once : 0,
    provisional : 1,
    appending : 0,
  }

  self._eventHandlerRegister( descriptor );

  return self;
}

//

function eventHandlerRegisterOneTime( kind, onHandle )
{
  var self = this;
  var owner;

  _.assert( arguments.length === 2 || arguments.length === 3,'eventHandlerRegisterOneTime:','expects "kind" and "onHandle" as arguments' );

  if( arguments.length === 3 )
  {
    owner = arguments[ 1 ];
    onHandle = arguments[ 2 ];
  }

  var descriptor =
  {
    kind : kind,
    onHandle : onHandle,
    owner : owner,
    once : 1,
    appending : 0,
  }

  self._eventHandlerRegister( descriptor );

  return self;
}

//

function eventHandlerRegisterEclipse( kind, onHandle )
{
  var self = this;
  var owner;

  _.assert( arguments.length === 2 || arguments.length === 3,'eventHandlerRegisterEclipse:','expects "kind" and "onHandle" as arguments' );

  if( arguments.length === 3 )
  {
    owner = arguments[ 1 ];
    onHandle = arguments[ 2 ];
  }

  var descriptor =
  {
    kind : kind,
    onHandle : onHandle,
    owner : owner,
    eclipse : 1,
    appending : 0,
  }

  self._eventHandlerRegister( descriptor );

  return self;
}

//
//
// function eventForbid( kinds )
// {
//   var self = this;
//   var owner;
//
//   _.assert( arguments.length === 1, 'expects single argument' );
//   _.assert( _.strIs( kinds ) || _.arrayIs( kinds ) );
//
//   var kinds = _.arrayAs( kinds );
//
//   function onHandle()
//   {
//     throw _.err( kinds.join( ' ' ),'event is forbidden in',self.nickName );
//   }
//
//   for( var k = 0 ; k < kinds.length ; k++ )
//   {
//
//     var kind = kinds[ k ];
//
//     var descriptor =
//     {
//       kind : kind,
//       onHandle : onHandle,
//       // forbidden : 1,
//       appending : 0,
//     }
//
//     self._eventHandlerRegister( descriptor );
//
//   }
//
//   return self;
// }
//
//

function _eventHandlerRegister( o )
{
  var self = this;
  var handlers = self._eventHandlerDescriptorsByKind( o.kind );

  if( _.arrayIs( o.kind ) )
  {
    for( var k = 0 ; k < o.kind.length ; k++ )
    {
      var d = _.mapExtend( null,o );
      d.kind = o.kind[ k ];
      self._eventHandlerRegister( d );
    }
    return self;
  }

  /* verification */

  _.assert( _.strIs( o.kind ) );
  _.assert( _.routineIs( o.onHandle ),'expects routine {-onHandle-}, but got',_.strTypeOf( o.oHandle ) );
  _.assertMapHasOnly( o,_eventHandlerRegister.defaults );
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( !( o.provisional && o.once ) );
  _.assert( !!self.constructor.prototype.Events || ( !self.constructor.prototype.strictEventHandling && self.constructor.prototype.strictEventHandling !== undefined ), 'expects static Events' );
  _.assert( !self.strictEventHandling || !!self.Events[ o.kind ], self.constructor.name, 'is not aware about event', _.strQuote( o.kind ) )

  // if( o.forbidden )
  // console.debug( 'REMINDER : forbidden event is not implemented!' );

  if( self._eventKinds && self._eventKinds.indexOf( kind ) === -1 )
  throw _.err( 'eventHandlerAppend:','Object does not support such kind of events :',kind,self );

  /* */

  o.onHandleEffective = o.onHandle;

  /* eclipse */

  if( o.eclipse )
  o.onHandleEffective = function handleEclipse()
  {
    var result = o.onHandle.apply( this,arguments );

    self._eventHandlerRemove
    ({
      kind : o.kind,
      onHandle : o.onHandle,
      strict : 0,
    });

    return result;
  }

  /* once */

  if( o.once )
  if( self._eventHandlerDescriptorByKindAndHandler( o.kind,o.onHandle ) )
  return self;

  if( o.once )
  o.onHandleEffective = function handleOnce()
  {
    var result = o.onHandle.apply( this,arguments );

    self._eventHandlerRemove
    ({
      kind : o.kind,
      onHandle : o.onHandle,
      strict : 0,
    });

    return result;
  }

  /* provisional */

  if( o.provisional )
  o.onHandleEffective = function handleProvisional()
  {
    var result = o.onHandle.apply( this,arguments );

    debugger;
    if( result === false )
    self._eventHandlerRemove
    ({
      kind : o.kind,
      onHandle : o.onHandle,
      strict : 0,
    });

    return result;
  }

  /* owner */

  if( o.owner !== undefined && o.owner !== null )
  self.eventHandlerRemoveByKindAndOwner( o.kind,o.owner );

  /* */

  if( o.appending )
  handlers.push( o );
  else
  handlers.unshift( o );

  /* kinds */

  if( self._eventKinds )
  {
    _.arrayAppendOnce( self._eventKinds,kind );
    debugger;
  }

  return self;
}

_eventHandlerRegister.defaults =
{
  kind : null,
  onHandle : null,
  owner : null,
  proxy : 0,
  once : 0,
  eclipse : 0,
  provisional : 0,
  appending : 1,
}

// --
// unregister
// --

function eventHandlerRemove()
{
  var self = this;

  if( !self._eventHandler.descriptors )
  return self;

  if( arguments.length === 0 )
  {

    self._eventHandlerRemove( Object.create( null ) );

  }
  else if( arguments.length === 1 )
  {

    if( _.strIs( arguments[ 0 ] ) )
    {

      self._eventHandlerRemove
      ({
        kind : arguments[ 0 ],
      });

    }
    else if( _.routineIs( arguments[ 0 ] ) )
    {

      self._eventHandlerRemove
      ({
        onHandle : arguments[ 0 ],
      });

    }
    else if( _.longIs( arguments[ 0 ] ) )
    {

      for( var i = 0; i < arguments[ 0 ].length; i++ )
      self.eventHandlerRemove( arguments[ 0 ][ i ] );

    }
    else throw _.err( 'unexpected' );

  }
  else if( arguments.length === 2 )
  {

    if( _.longIs( arguments[ 0 ] ) )
    {

      for( var i = 0; i < arguments[ 0 ].length; i++ )
      self.eventHandlerRemove( arguments[ 0 ][ i ], arguments[ 1 ] );

    }
    else if( _.routineIs( arguments[ 1 ] ) )
    {

      self._eventHandlerRemove
      ({
        kind : arguments[ 0 ],
        onHandle : arguments[ 1 ],
      });

    }
    else
    {
      self._eventHandlerRemove
      ({
        kind : arguments[ 0 ],
        owner : arguments[ 1 ],
      });
    }
  }
  else _.assert( 0, 'unexpected' );

  return self;
}

//

function _eventHandlerRemove( o )
{
  var self = this;

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assertMapHasOnly( o,_eventHandlerRemove.defaults );
  if( Object.keys( o ).length && o.strict === undefined )
  o.strict = 1;

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return self;

  var length = Object.keys( o ).length;

  if( o.kind !== undefined )
  _.assert( _.strIs( o.kind ),'expects "kind" as string' );

  if( o.onHandle !== undefined )
  _.assert( _.routineIs( o.onHandle ),'expects "onHandle" as routine' );

  if( length === 0 )
  {

    for( var h in handlers )
    handlers[ h ].splice( 0,handlers[ h ].length );

  }
  else if( length === 1 && o.kind )
  {

    var handlers = handlers[ o.kind ];
    if( !handlers )
    return self;

    handlers.splice( 0,handlers.length );

  }
  else
  {

    function equalizer( a,b )
    {

      if( o.kind !== undefined )
      if( a.kind !== b.kind )
      return false;

      if( o.onHandle !== undefined )
      if( a.onHandle !== b.onHandle )
      return false;

      if( o.owner !== undefined )
      if( a.owner !== b.owner )
      return false;

      return true;
    }

    // console.error( 'REMINDER','fix me' ); debugger; xxx
    // return;

    var removed = 0;
    if( o.kind )
    {

      var handlers = handlers[ o.kind ];
      if( handlers )
      removed = _.arrayRemovedAll( handlers,o,equalizer );

    }
    else for( var h in handlers )
    {

      removed += _.arrayRemovedAll( handlers[ h ],o,equalizer );

    }

    _.assert( removed || !o.onHandle || !o.strict, 'handler was not registered to unregister it' );

  }

  return self;
}

_eventHandlerRemove.defaults =
{
  kind : null,
  onHandle : null,
  owner : null,
  strict : 1,
}

//

function eventHandlerRemoveByKindAndOwner( kind, owner )
{
  var self = this;

  _.assert( arguments.length === 2 && !!owner, 'eventHandlerRemove:', 'expects "kind" and "owner" as arguments' );

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return self;

  handlers = handlers[ kind ];
  if( !handlers )
  return self;

  do
  {

    var descriptor = self._eventHandlerDescriptorByKindAndOwner( kind,owner );

    if( descriptor )
    _.arrayRemoveOnce( handlers,descriptor );

  }
  while( descriptor );

  return self;
}


// --
// handle
// --

function eventGive( event )
{
  var self = this;

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.routineIs( self._eventGive ) );

  if( _.strIs( event ) )
  event = { kind : event };

  return self._eventGive( event,Object.create( null ) );
}

//

function eventHandleUntil( event,value )
{
  var self = this;

  _.assert( arguments.length === 2, 'expects exactly two arguments' );

  if( _.strIs( event ) )
  event = { kind : event };

  return self._eventGive( event,{ until : value } );
}

//

function eventHandleSingle( event )
{
  var self = this;

  _.assert( arguments.length === 1, 'expects single argument' );

  if( _.strIs( event ) )
  event = { kind : event };

  return self._eventGive( event,{ single : 1 } );
}

//

function _eventGive( event,o )
{
  var self = this;
  var result = o.result = o.result || [];
  var untilFound = 0;

  _.assert( arguments.length === 2, 'expects exactly two arguments' );
  _.assert( event.type === undefined || event.kind !== undefined, 'event should have "kind" field, no "type" field' );
  _.assert( !!self.constructor.prototype.Events || ( !self.constructor.prototype.strictEventHandling && self.constructor.prototype.strictEventHandling !== undefined ), 'expects static Events' );
  _.assert( !self.strictEventHandling || !!self.Events[ event.kind ], () => self.constructor.name + ' is not aware about event ' + _.strQuote( event.kind ) );
  _.assert( _.objectIs( self._eventHandler ) );

  if( self.eventVerbosity )
  logger.log( 'fired event', self.nickName + '.' + event.kind );

  /* pre */

  var handlers = self._eventHandler.descriptors;
  if( handlers === undefined )
  return result;

  var handlerArray = handlers[ event.kind ];
  if( handlerArray === undefined )
  return result;

  handlerArray = handlerArray.slice( 0 );

  event.target = self;

  if( self.eventVerbosity )
  logger.up();

  if( o.single )
  _.assert( handlerArray.length <= 1,'expects single handler, but has ' + handlerArray.length );

  /* iterate */

  for( var i = 0, il = handlerArray.length; i < il; i ++ )
  {

    var handler = handlerArray[ i ];

    if( self.eventVerbosity )
    logger.log( event.kind,'caught by',handler.onHandle.name );

    if( handler.proxy )
    {
      handler.onHandleEffective.call( self, event, o );
    }
    else
    {

      result.push( handler.onHandleEffective.call( self, event ) );
      if( o.until !== undefined )
      {
        if( result[ result.length-1 ] === o.until )
        {
          untilFound = 1;
          result = o.until;
          break;
        }
      }

    }

    if( handler.eclipse )
    break;

  }

  /* post */

  if( self.eventVerbosity )
  logger.down();

  if( o.single )
  result = result[ 0 ];

  if( o.until && !untilFound )
  result = undefined;

  return result;
}

//

function eventWaitFor( kind )
{
  var self = this;
  var con = new _.Consequence();

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( kind ) );

  var descriptor =
  {
    kind : kind,
    onHandle : function( e,o )
    {
      _.timeOut( 0,() => con.give( e ) );
    },
    eclipse : 0,
    once : 1,
    appending : 1,
  }

  self._eventHandlerRegister( descriptor );

  return con;
}

// --
// get
// --

function _eventHandlerDescriptorByKindAndOwner( kind,owner )
{
  var self = this;

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return;

  handlers = handlers[ kind ];
  if( !handlers )
  return;

  _.assert( arguments.length === 2, 'expects exactly two arguments' );

  function eq( a,b ){ return a.kind === b.kind && a.owner === b.owner; };
  var element = { kind : kind, owner : owner };
  var index = _.arrayRightIndex( handlers, element, eq );

  if( !( index >= 0 ) )
  return;

  var result = handlers[ index ];
  result.index = index;

  return result;
}

//

function _eventHandlerDescriptorByKindAndHandler( kind,onHandle )
{
  var self = this;

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return;

  handlers = handlers[ kind ];
  if( !handlers )
  return;

  _.assert( arguments.length === 2, 'expects exactly two arguments' );

  function eq( a,b ){ return a.kind === b.kind && a.onHandle === b.onHandle; };
  var element = { kind : kind, onHandle : onHandle };
  var index = _.arrayRightIndex( handlers, element, eq );

  if( !( index >= 0 ) )
  return;

  var result = handlers[ index ];
  result.index = index;

  return result;
}

//

function _eventHandlerDescriptorByHandler( onHandle )
{
  var self = this;

  _.assert( _.routineIs( onHandle ) );
  _.assert( arguments.length === 1, 'expects single argument' );

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return;

  for( var h in handlers )
  {

    var index = _.arrayRightIndex( handlers[ h ],{ onHandle : onHandle },( a,b ) => a.onHandle === b.onHandle );

    if( index >= 0 )
    {
      handlers[ h ][ index ].index = index;
      return handlers[ h ][ index ];
    }

  }

}

//

function _eventHandlerDescriptorsByKind( kind )
{
  var self = this;

  _.assert( _.objectIs( self._eventHandler ) );

  if( !self._eventHandler.descriptors )
  debugger;

  var handlers = self._eventHandler.descriptors;
  var handlers = handlers[ kind ] = handlers[ kind ] || [];

  return handlers;
}

//

function _eventHandlerDescriptorsAll()
{
  var self = this;
  var result = [];

  debugger;

  for( var d in self._eventHandler.descriptors )
  {
    var descriptor = self._eventHandler.descriptors[ d ];

    debugger;
    result.push( descriptor );

  }

  return result;
}

//

function eventHandlerDescriptorsFilter( filter )
{
  var self = this;
  var handlers = filter.kind ? self._eventHandlerDescriptorsByKind( filter.kind ) : self._eventHandlerDescriptorsAll( filter.kind );

  if( _.objectIs( filter ) )
  _.assertMapHasOnly( filter,eventHandlerDescriptorsFilter.defaults );

  debugger;

  var result = _.entityFilter( handlers, filter );

  debugger;
}

eventHandlerDescriptorsFilter.defaults =
{
  kind : null,
  onHandle : null,
  owner : null,
}

// --
// proxy
// --

function eventProxyTo( dstPrototype,rename )
{
  var self = this;

  _.assert( arguments.length === 2, 'expects exactly two arguments' );
  _.assert( _.objectIs( dstPrototype ) || _.arrayIs( dstPrototype ) );
  _.assert( _.mapIs( rename ) || _.strIs( rename ) );

  if( _.arrayIs( dstPrototype ) )
  {
    for( var d = 0 ; d < dstPrototype.length ; d++ )
    self.eventProxyTo( dstPrototype[ d ],rename );
    return self;
  }

  /* */

  _.assert( _.routineIs( dstPrototype.eventGive ) );
  _.assert( _.routineIs( dstPrototype._eventGive ) );

  if( _.strIs( rename ) )
  {
    var r = Object.create( null );
    r[ rename ] = rename;
    rename = r;
  }

  /* */

  for( var r in rename ) ( function()
  {
    var name = r;
    _.assert( rename[ r ] && _.strIs( rename[ r ] ),'eventProxyTo :','expects name as string' );

    var descriptor =
    {
      kind : r,
      onHandle : function( event,o )
      {
        if( name !== rename[ name ] )
        {
          event = _.mapExtend( null,event );
          event.kind = rename[ name ];
        }
        return dstPrototype._eventGive( event,o );
      },
      owner : dstPrototype,
      proxy : 1,
      appending : 1,
    }

    self._eventHandlerRegister( descriptor );

  })();

  return self;
}

//

function eventProxyFrom( src,rename )
{
  var self = this;

  _.assert( arguments.length === 2, 'expects exactly two arguments' );

  if( _.arrayIs( src ) )
  {
    for( var s = 0 ; s < src.length ; s++ )
    self.eventProxyFrom( src[ s ],rename );
    return self;
  }

  return src.eventProxyTo( self,rename );
}

// --
// relations
// --

var Groups =
{
  Events : 'Events',
}

var Composes =
{
}

var Restricts =
{

  eventVerbosity : 0,
  _eventHandler : _.define.own( {} ),

}

var Statics =
{

  strictEventHandling : 1,

}

var Events =
{
  init : 'init',
  finit : 'finit',
}

var Forbids =
{
  _eventHandlers : '_eventHandlers',
  _eventHandlerOwners : '_eventHandlerOwners',
  _eventHandlerDescriptors : '_eventHandlerDescriptors',
}

// --
// declaration
// --

var Supplement =
{

  // register

  _eventHandlerInit : _eventHandlerInit,
  _eventHandlerFinit : _eventHandlerFinit,

  eventReport : eventReport,

  eventHandlerPrepend : eventHandlerPrepend,
  eventHandlerAppend : eventHandlerAppend,
  addEventListener : eventHandlerAppend,
  on : eventHandlerAppend,

  eventHandlerRegisterProvisional : eventHandlerRegisterProvisional,
  provisional : eventHandlerRegisterProvisional,

  eventHandlerRegisterOneTime : eventHandlerRegisterOneTime,
  once : eventHandlerRegisterOneTime,

  eventHandlerRegisterEclipse : eventHandlerRegisterEclipse,
  eclipse : eventHandlerRegisterEclipse,

  _eventHandlerRegister: _eventHandlerRegister,

  // unregister

  removeListener : eventHandlerRemove,
  removeEventListener : eventHandlerRemove,
  off : eventHandlerRemove,
  eventHandlerRemove : eventHandlerRemove,
  _eventHandlerRemove : _eventHandlerRemove,

  eventHandlerRemoveByKindAndOwner : eventHandlerRemoveByKindAndOwner,

  // handle

  dispatchEvent : eventGive,
  emit : eventGive,
  eventGive : eventGive,
  eventHandleUntil : eventHandleUntil,
  eventHandleSingle : eventHandleSingle,

  _eventGive : _eventGive,

  eventWaitFor : eventWaitFor,

  // get

  _eventHandlerDescriptorByKindAndOwner : _eventHandlerDescriptorByKindAndOwner,
  _eventHandlerDescriptorByKindAndHandler : _eventHandlerDescriptorByKindAndHandler,
  _eventHandlerDescriptorByHandler : _eventHandlerDescriptorByHandler,
  _eventHandlerDescriptorsByKind : _eventHandlerDescriptorsByKind,
  _eventHandlerDescriptorsAll : _eventHandlerDescriptorsAll,
  eventHandlerDescriptorsFilter : eventHandlerDescriptorsFilter,

  // proxy

  eventProxyTo : eventProxyTo,
  eventProxyFrom : eventProxyFrom,

  // relations

  Groups : Groups,
  Composes : Composes,
  Restricts : Restricts,
  Statics : Statics,
  Events : Events,
  Forbids : Forbids,

}

//

var Functors =
{

  init : init,
  finit : finit,

}

//

_.classDeclare
({
  cls : Self,
  supplement : Supplement,
  onMixin : onMixin,
  // onMixinEnd : onMixinEnd,
  functors : Functors,
  withMixin : true,
  withClass : true,
});

// //
//
// var Self =
// {
//
//   functors : Functors,
//   supplement : Supplement,
//
//   onMixin : onMixin,
//   name : 'wEventHandler',
//   shortName : 'EventHandler',
//
// }
//
//

_.assert( _.mapIs( _.DefaultFieldsGroups ) );
// debugger;
// _.DefaultFieldsGroups.Events = 'Events';
// debugger;

// --
// export
// --

// _global_[ Self.name ] = _[ Self.shortName ] = _.mixinDelcare( Self );
_global_[ Self.name ] = _[ Self.shortName ] = Self;

if( typeof module !== 'undefined' )
if( _global_.WTOOLS_PRIVATE )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
