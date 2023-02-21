import "package:example/pages/home.dart";
import "package:example/pages/infinite_query.dart";
import "package:example/pages/query.dart";
import "package:go_router/go_router.dart";

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/query',
      builder: (context, state) => const QueryPage(),
    ),
    GoRoute(
      path: '/infinite-query',
      builder: (context, state) => const InfiniteQueryPageWidget(),
    ),
  ],
);
