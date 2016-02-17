import 'dart:html';

enum UIStates {
  init,
  data,
  prepare,
  group,
  sync,
  display,
  end
}

class UILoader {
  Element _element;
  Element _text;
  Map<UIStates, String> _states = {
    UIStates.init: 'Initializing',
    UIStates.data: 'Getting data from server',
    UIStates.prepare: 'Preparing locations',
    UIStates.group: 'Groupping branches by cities',
    UIStates.sync: 'Synchronizing OSM and NP branches',
    UIStates.display: 'Rendering',
    UIStates.end: 'Done'
  };

  UILoader(Element element) {
    _element = element;
    _text = _element.querySelector('.title');
  }

  setState(UIStates state, [String description]) {
    _element.classes.toggle('loading', state != UIStates.end);
    var text = _states[state];
    if (description != null)
      text += ' ($description)';
    _text.text = text;
    // Force render wait.
    return window.animationFrame;
  }
}