( function _EventHandler_s_() {

'use strict';

var _ = wTools;
var _hasOwnProperty = Object.hasOwnProperty;

if( typeof module !== 'undefined' )
{

  if( typeof wTools === 'undefined' || !wTools.mixin )
  try
  {
    require( '../component/Proto.s' );
  }
  catch( err )
  {
    require( 'wProto' );
  }

}

//

/**
 * Mixin this methods into prototype of another object.
 * @param {object} dst - prototype of another object.
 * @method copy
 * @memberof wEventHandler#
 */

var mixin = function( constructor )
{

  var dst = constructor.prototype;

  _.mixin
  ({
    dst : dst,
    mixin : Self,
  });

  _.accessorForbid( dst,
  {
    _eventHandlers : '_eventHandlers',
    _eventHandlerOwners : '_eventHandlerOwners',
    _eventHandlerDescriptors : '_eventHandlerDescriptors',
  });

  _.assert( dst.Restricts._eventHandler );
  _.assert( arguments.length === 1 );
  _.assert( _.routineIs( constructor ) );

}

// --
// Functor
// --

/**
 * Functor to produce init.
 * @param { routine } original - original method.
 * @method init
 * @memberof wEventHandler#
 */

var init = function( original )
{

  return function initEventHandler()
  {
    var self = this;

    _.assert( !self._eventHandler,'EventHandler.init already done for ',self.nickName );

    self._eventHandlerInit();

    var result = original.apply( self,arguments );

    self.eventHandle( 'init' );

    return result;
  }

}

//

/**
 * Functor to produce finit.
 * @param { routine } original - original method.
 * @method finit
 * @memberof wEventHandler#
 */

var finit = function( original )
{

/*
  if( !originalFinit )
  {
    debugger;
    console.warn( 'finit is not defined' );
    return;
  }
*/

  return function finitEventHandler()
  {
    var self = this;

    self.eventHandle( 'finit' );

    if( original )
    var result = original.apply( self,arguments );

    self.eventHandlerUnregister();

    return result;
  }

}

// --
// register
// --

var _eventHandlerInit = function()
{
  var self = this;

  _.assert( self instanceof self.constructor );

  //if( _global_.wVisualiser && self instanceof _global_.wVisualiser )
  //debugger;

  self._eventHandler = {};
  self._eventHandler.descriptors = {};

}

//

var eventHandlerPrepend = function( kind, onHandle )
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

var eventHandlerAppend = function( kind, onHandle )
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

var eventHandlerRegisterProvisional = function( kind, onHandle )
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

var eventHandlerRegisterOneTime = function( kind, onHandle )
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

var eventHandlerRegisterEclipse = function( kind, onHandle )
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

var _eventHandlerRegister = function _eventHandlerRegister( o )
{
  var self = this;
  var handlers = self._eventHandlerDescriptorsByKind( o.kind );

  if( _.arrayIs( o.kind ) )
  for( var k = 0 ; k < o.kind.length ; k++ )
  {
    var d = _.mapExtend( {},o );
    d.kind = o.kind[ k ];
    self._eventHandlerRegister( d );
    return;
  }

  // verification

  _.assert( _.strIs( o.kind ) );
  _.assert( _.routineIs( o.onHandle ) );
  _.assertMapHasOnly( o,_eventHandlerRegister.defaults );
  _.assert( arguments.length === 1 );
  _.assert( !( o.provisional && o.once ) );

  if( o.forbidden )
  console.warn( 'REMINDER : forbidden event is not implemented!' );

  if( self._eventKinds && self._eventKinds.indexOf( kind ) === -1 )
  throw _.err( 'eventHandlerAppend:','Object does not support such kind of events:',kind,self );

  //

  o.onHandleEffective = o.onHandle;

  // eclipse

  if( o.eclipse )
  o.onHandleEffective = function handleEclipse()
  {
    var result = o.onHandle.apply( this,arguments );

    self._eventHandlerUnregister
    ({
      kind : o.kind,
      onHandle : o.onHandle,
      strict : 0,
    });

    return result;
  }

  // once

  if( o.once )
  if( self._eventHandlerDescriptorByKindAndHandler( o.kind,o.onHandle ) )
  return self;

  if( o.once )
  o.onHandleEffective = function handleOnce()
  {
    var result = o.onHandle.apply( this,arguments );

    self._eventHandlerUnregister
    ({
      kind : o.kind,
      onHandle : o.onHandle,
      strict : 0,
    });

    return result;
  }

  // provisional

  if( o.provisional )
  o.onHandleEffective = function handleProvisional()
  {
    var result = o.onHandle.apply( this,arguments );

    debugger;
    if( result === false )
    self._eventHandlerUnregister
    ({
      kind : o.kind,
      onHandle : o.onHandle,
      strict : 0,
    });

    return result;
  }

  // owner

  if( o.owner !== undefined && o.owner !== null )
  self.eventHandlerUnregisterByKindAndOwner( o.kind,o.owner );

  //

  if( o.appending )
  handlers.push( o );
  else
  handlers.unshift( o );

  // kinds

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
  forbidden : 0,
  appending : 1,
}

//

var eventForbid = function( kinds )
{
  var self = this;
  var owner;

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( kinds ) || _.arrayIs( kinds ) );

  var kinds = _.arrayAs( kinds );

  var onHandle = function()
  {
    throw _.err( kinds.join( ' ' ),'event is forbidden in',self.nickName );
  }

  for( var k = 0 ; k < kinds.length ; k++ )
  {

    var kind = kinds[ k ];

    var descriptor =
    {
      kind : kind,
      onHandle : onHandle,
      forbidden : 1,
      appending : 0,
    }

    self._eventHandlerRegister( descriptor );

  }

  return self;
}

// --
// unregister
// --

var eventHandlerUnregister = function( kind, onHandle )
{
  var self = this;

  if( !self._eventHandler.descriptors )
  return self;

  if( arguments.length === 0 )
  {

    self._eventHandlerUnregister({});

  }
  else if( arguments.length === 1 )
  {

    if( _.strIs( arguments[ 0 ] ) )
    {

      self._eventHandlerUnregister
      ({
        kind : arguments[ 0 ],
      });

    }
    else if( _.routineIs( arguments[ 0 ] ) )
    {

      self._eventHandlerUnregister
      ({
        onHandle : arguments[ 0 ],
      });

    }
    else throw _.err( 'unexpected' );

  }
  else if( arguments.length === 2 )
  {

    if( _.strIs( onHandle ) )
    self._eventHandlerUnregister
    ({
      kind : kind,
      owner : onHandle,
    });
    else
    self._eventHandlerUnregister
    ({
      kind : kind,
      onHandle : onHandle,
    });

  }
  else throw _.err( 'unexpected' );

  return self;
}

//

var _eventHandlerUnregister = function( o )
{
  var self = this;

/*
  if( self.name === 'cells cloud' )
  debugger;
*/

  _.assert( arguments.length === 1 );
  _.assertMapHasOnly( o,_eventHandlerUnregister.defaults );
  if( Object.keys( o ).length && o.strict === undefined )
  o.strict = 1;

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return self;

  var length = Object.keys( o ).length;

  if( o.kind !== undefined )
  _.assert( _.strIs( o.kind ),'eventHandlerUnregister:','expects "kind" as string' );

  if( o.onHandle !== undefined )
  _.assert( _.routineIs( o.onHandle ),'eventHandlerUnregister:','expects "onHandle" as routine' );

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

    var equalizer = function( a,b )
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

    if( !removed && o.onHandle && o.strict )
    throw _.err( 'eventHandlerUnregister :','handler was not registered to unregister it' );

  }

  return self;
}

_eventHandlerUnregister.defaults =
{
  kind : null,
  onHandle : null,
  owner : null,
  strict : 1,
}

//

var eventHandlerUnregisterByKindAndOwner = function( kind, owner )
{
  var self = this;

  _.assert( arguments.length === 2 && owner,'eventHandlerUnregister:','expects "kind" and "owner" as arguments' );

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

var eventHandle = function( event )
{
  var self = this;

  _.assert( arguments.length === 1 );
  _.assert( self instanceof self.constructor );

  if( _.strIs( event ) )
  event = { kind : event };

  return self._eventHandle( event,{} );
}

//

var eventHandleUntil = function( event,value )
{
  var self = this;

  _.assert( arguments.length === 2 );

  if( _.strIs( event ) )
  event = { kind : event };

  return self._eventHandle( event,{ until : value } );
}

//

var eventHandleSingle = function( event )
{
  var self = this;

  _.assert( arguments.length === 1 );

  if( _.strIs( event ) )
  event = { kind : event };

  return self._eventHandle( event,{ single : 1 } );
}

//

var _eventHandle = function( event,o )
{
  var self = this;
  var result = o.result = o.result || [];
  var untilFound = 0;

/*
  if( event.kind === 'finit' )
  debugger;
*/

  _.assert( arguments.length === 2 );

  if( event.type !== undefined || event.kind === undefined )
  throw _.err( 'event should have "kind" field, no "type" field' );

  if( self.usingEventLogging )
  logger.log( 'fired event', self.nickName + '.' + event.kind );

  if( !self._eventHandler )
  debugger;

  var handlers = self._eventHandler.descriptors;
  if( handlers === undefined )
  return result;

  var handlerArray = handlers[ event.kind ];
  if( handlerArray === undefined )
  return result;

  handlerArray = handlerArray.slice( 0 );

  event.target = self;

  if( self.usingEventLogging )
  logger.up();

  if( o.single )
  _.assert( handlerArray.length <= 1,'expects single handler, but has ' + handlerArray.length );

  //

  for( var i = 0, il = handlerArray.length; i < il; i ++ )
  {

    var handler = handlerArray[ i ];

    if( self.usingEventLogging )
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

  //

  if( self.usingEventLogging )
  logger.down();

  if( o.single )
  result = result[ 0 ];

  if( o.until && !untilFound )
  result = undefined;

  return result;
}

// --
// get
// --

var _eventHandlerDescriptorByKindAndOwner = function( kind,owner )
{
  var self = this;

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return;

  handlers = handlers[ kind ];
  if( !handlers )
  return;

  _.assert( arguments.length === 2 );

  var eq = function( a,b ){ return a.kind === b.kind && a.owner === b.owner; };
  var element = { kind : kind, owner : owner };
  var index = _.arrayLeftIndexOf( handlers,element,eq );

  if( !( index >= 0 ) )
  return;

  var result = handlers[ index ];
  result.index = index;

  return result;
}

//

var _eventHandlerDescriptorByKindAndHandler = function( kind,onHandle )
{
  var self = this;

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return;

  handlers = handlers[ kind ];
  if( !handlers )
  return;

  _.assert( arguments.length === 2 );

  var eq = function( a,b ){ return a.kind === b.kind && a.onHandle === b.onHandle; };
  var element = { kind : kind, onHandle : onHandle };
  var index = _.arrayLeftIndexOf( handlers,element,eq );

  if( !( index >= 0 ) )
  return;

  var result = handlers[ index ];
  result.index = index;

  return result;
}

//

var _eventHandlerDescriptorByHandler = function( onHandle )
{
  var self = this;

  _.assert( _.routineIs( onHandle ) );
  _.assert( arguments.length === 1 );

  var handlers = self._eventHandler.descriptors;
  if( !handlers )
  return;

  for( var h in handlers )
  {

    var index = _.arrayLeftIndexOf( handlers[ h ],{ onHandle : onHandle },function( a,b ){ return a.onHandle === b.onHandle } );

    if( index >= 0 )
    {
      handlers[ h ][ index ].index = index;
      return handlers[ h ][ index ];
    }

  }

}

//

var _eventHandlerDescriptorsByKind = function( kind )
{
  var self = this;

  var handlers = self._eventHandler.descriptors;
  var handlers = handlers[ kind ] = handlers[ kind ] || [];

  return handlers;
}

// --
// proxy
// --

var eventProxyTo = function( dst,rename )
{
  var self = this;

  _.assert( arguments.length === 2 );
  _.assert( _.objectIs( dst ) || _.arrayIs( dst ) );
  _.assert( _.mapIs( rename ) || _.strIs( rename ) );

  if( _.arrayIs( dst ) )
  {
    for( var d = 0 ; d < dst.length ; d++ )
    self.eventProxyTo( dst[ d ],rename );
    return self;
  }

  _.assert( _.routineIs( dst.eventHandle ) );

  if( _.strIs( rename ) )
  {
    var r = {};
    r[ rename ] = rename;
    rename = r;
  }

  for( var r in rename ) (function()
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
          event = _.mapExtend( {},event );
          event.kind = rename[ name ];
        }
        return dst._eventHandle( event,o );
      },
      proxy : 1,
      appending : 1,
    }
    self._eventHandlerRegister( descriptor );

  })();

  return self;
}

//

var eventProxyFrom = function( src,rename )
{
  var self = this;

  _.assert( arguments.length === 2 );

  if( _.arrayIs( src ) )
  {
    for( var s = 0 ; s < src.length ; s++ )
    self.eventProxyFrom( src[ s ],rename );
    return self;
  }

  return src.eventProxyTo( self,rename );
}

// --
// relationships
// --

var Composes =
{
}

var Restricts =
{

  usingEventLogging : 0,
  _eventHandler : {},

}

// --
// proto
// --

var Supplement =
{

  // register

  _eventHandlerInit : _eventHandlerInit,

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


  eventForbid : eventForbid,


  // unregister

  removeListener : eventHandlerUnregister,
  removeEventListener : eventHandlerUnregister,
  eventHandlerUnregister : eventHandlerUnregister,
  _eventHandlerUnregister : _eventHandlerUnregister,
  eventHandlerUnregisterByKindAndOwner: eventHandlerUnregisterByKindAndOwner,


  // handle

  dispatchEvent : eventHandle,
  emit : eventHandle,
  eventHandle : eventHandle,
  eventHandleUntil : eventHandleUntil,
  eventHandleSingle : eventHandleSingle,
  _eventHandle : _eventHandle,


  // get

  _eventHandlerDescriptorByKindAndOwner : _eventHandlerDescriptorByKindAndOwner,
  _eventHandlerDescriptorByKindAndHandler : _eventHandlerDescriptorByKindAndHandler,
  _eventHandlerDescriptorByHandler : _eventHandlerDescriptorByHandler,
  _eventHandlerDescriptorsByKind : _eventHandlerDescriptorsByKind,


  // proxy

  eventProxyTo : eventProxyTo,
  eventProxyFrom : eventProxyFrom,


  // relationships

  Composes : Composes,
  Restricts : Restricts,

}

//

var Functor =
{

  init : init,
  finit : finit,

}

//

var Self =
{

  Functor : Functor,
  Supplement : Supplement,

  mixin : mixin,
  name : 'EventHandler',

}

_global_.wEventHandler = wTools.EventHandler = Self;

return Self;

})();
