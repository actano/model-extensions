// Generated by CoffeeScript 1.9.1
(function() {
  var PostSetAction, getPropertyNameOfSetter, lowercaseFirstChar, startsWith;

  lowercaseFirstChar = function(string) {
    return string.charAt(0).toLowerCase() + string.slice(1);
  };

  getPropertyNameOfSetter = function(setterName) {
    return lowercaseFirstChar(setterName.slice(3));
  };

  startsWith = function(candidate, query) {
    return candidate.indexOf(query) === 0;
  };

  PostSetAction = function(prototype, action) {
    var fn, i, len, listSetterNames, postExtendSetter, ref, setterName;
    listSetterNames = function() {
      var propertyKey, propertyValue, setterNames;
      setterNames = [];
      for (propertyKey in prototype) {
        propertyValue = prototype[propertyKey];
        if (startsWith(propertyKey, "set")) {
          setterNames.push(propertyKey);
        }
      }
      return setterNames;
    };
    postExtendSetter = function(setterName, extension) {
      var originalSetter;
      originalSetter = prototype[setterName];
      return prototype[setterName] = function(newValue) {
        var oldValue, propertyName;
        propertyName = getPropertyNameOfSetter(setterName);
        oldValue = this["_" + propertyName];
        originalSetter.apply(this, [newValue]);
        extension.apply(this, [propertyName, newValue, oldValue]);
        return newValue;
      };
    };
    ref = listSetterNames();
    fn = function(setterName) {
      return postExtendSetter(setterName, action);
    };
    for (i = 0, len = ref.length; i < len; i++) {
      setterName = ref[i];
      fn(setterName);
    }
    return prototype;
  };

  module.exports.PostSetAction = PostSetAction;

}).call(this);