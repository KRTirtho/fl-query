import 'package:fl_query/fl_query.dart';

var todos = [
  {"userId": 1, "id": 1, "title": "delectus aut autem", "completed": false},
  {
    "userId": 1,
    "id": 2,
    "title": "quis ut nam facilis et officia qui",
    "completed": false
  },
  {"userId": 1, "id": 3, "title": "fugiat veniam minus", "completed": false},
  {"userId": 1, "id": 4, "title": "et porro tempora", "completed": true},
  {
    "userId": 1,
    "id": 5,
    "title": "laboriosam mollitia et enim quasi adipisci quia provident illum",
    "completed": false
  },
  {
    "userId": 1,
    "id": 6,
    "title": "qui ullam ratione quibusdam voluptatem quia omnis",
    "completed": false
  },
];

void main() async {
  try {
    var key = QueryKey("TEST");
    QueryClient queryClient = QueryClient();
    queryClient.mount();
    var data = await queryClient.fetchQuery<Map, dynamic, Map>(
      queryKey: key,
      queryFn: (context) {
        return Future.value(todos.first);
      },
    );
    print("======FETCHED DATA======");
    print(data);
    print("======CACHED DATA======");
    print(queryClient.getQueryData(key));
    queryClient.setQueryData<Map>(key, (prevData) {
      return {
        ...(prevData) ?? {},
        "title": "Yehi aloh heh",
        "completed": true,
      };
    });
    print("======CACHED DATA======");
    print(queryClient.getQueryData(key));
    print("======STATE======");
    print(queryClient.getQueryState(key)?.toJson());
  } catch (e) {
    print(e);
  }
}
