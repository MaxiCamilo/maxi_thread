enum IsolatedThreadMessageType { newFunction, confirmation, result, interactionValue, cancel, closed }

class IsolatedThreadMessage {
  final IsolatedThreadMessageType type;
  final int identifier;
  final dynamic content;

  const IsolatedThreadMessage({required this.type, required this.identifier, required this.content});
}
