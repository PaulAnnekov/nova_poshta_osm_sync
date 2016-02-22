class UILoader {
  _element : Element;
  _text : Element;
  _states : { [email: string]: string; } = {
    'init': 'Initializing',
    'data': 'Getting data from server',
    'prepare': 'Preparing locations',
    'group': 'Groupping branches by cities',
    'sync': 'Synchronizing OSM and NP branches',
    'display': 'Rendering',
    'end': 'Done'
  };

  constructor(element: Element) {
    this._element = element;
    this._text = this._element.querySelector('.title');
  }

  async setState(state: string, description?: string) {
    this._element.classList.toggle('loading', state != 'end');
    var text = this._states[state];
    if (description != null)
      text += ' ($description)';
    this._text.textContent = text;
    return new Promise<void>(resolve => {
      window.requestAnimationFrame(resolve);
    });
  }
}