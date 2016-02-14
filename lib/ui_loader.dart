import 'dart:html';

enum UIStates {
  init,
  data,
  prepare,
  group,
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
    UIStates.display: 'Rendering',
    UIStates.end: 'Done'
  };

  UILoader(Element element) {
    _element = element;
    _text = _element.querySelector('.title');
  }

  setState(UIStates state) {
    _element.classes.toggle('loading', state != UIStates.end);
    _text.text = _states[state];
  }
}