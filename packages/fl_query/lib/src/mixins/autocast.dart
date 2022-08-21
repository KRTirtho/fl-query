mixin AutoCast {
  A? cast<A>() => this is A ? this as A : null;
}
