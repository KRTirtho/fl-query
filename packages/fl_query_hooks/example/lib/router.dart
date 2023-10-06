import "package:fl_query_hooks_example/pages/home.dart";
import "package:fl_query_hooks_example/pages/infinite_query.dart";
import "package:fl_query_hooks_example/pages/mutation/mutation.dart";
import "package:fl_query_hooks_example/pages/query.dart";
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
    GoRoute(
      path: '/mutation',
      builder: (context, state) => const MutationPage(),
    ),
  ],
);
