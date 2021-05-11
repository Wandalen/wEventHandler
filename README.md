# module::EventHandler [![status](https://github.com/Wandalen/wEventHandler/actions/workflows/StandardPublish.yml/badge.svg)](https://github.com/Wandalen/wEventHandler/actions/workflows/StandardPublish.yml) [![experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/emersion/stability-badges#experimental)

Mixin adds events dispatching mechanism to your class. EventHandler provides methods to bind/unbind handler of an event, to handle a specific event only once, to associate an event with a namespace what later make possible to unbind handler of event with help of namespace. EventHandler allows redirecting events to/from another instance. Unlike alternative implementation of the concept, EventHandler is strict by default and force developer to explicitly declare / bind / unbind all events supported by object. Use it to add events dispatching mechanism to your classes and avoid accumulation of technical dept and potential errors.

### Try out from the repository
```
git clone https://github.com/Wandalen/wEventHandler
cd wEventHandler
npm install
node sample/trivial/Sample.s
```

### To add to your project
```
npm add 'wEventHandler@alpha'
```

