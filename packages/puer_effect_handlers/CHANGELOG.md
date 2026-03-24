## NEXT

- Add StreamEffectHandler (#46)
- Make `effectMapper` and `messageMapper` optional in `MapEffectHandler` and
  `MapEffectHandlerExt.map()` (#65). When omitted, a direct runtime type cast
  is used as a fallback. Effects or messages that cannot be cast are silently
  dropped.
- Mapper functions may now return `null` to explicitly drop an effect or
  message (`Transform<From, To?>` signature).

## 1.0.0-alpha.1

- Initial release
