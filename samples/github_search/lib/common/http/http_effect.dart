sealed class HttpEffect {
  const HttpEffect._();
}

final class HttpGetEffect implements HttpEffect {
  final Uri url;

  const HttpGetEffect({required this.url});
}
