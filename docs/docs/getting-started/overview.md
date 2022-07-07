---
sidebar_position: 1
id: overview
---

# Overview

Fl-Query is a asynchronous data manager for Flutter that caches, fetches, automatically refetches stale data. Basically, its [React-Query](https://react-query.tanstack.com/) but for Flutter. But that doesn't mean it's a direct port of React-Query. Instead the concept of React-Query is implemented by Fl-Query

## What does it offer?

- Async data caching & invalidation
- Smart refetch in the background every time data becomes stale
- Declarative way to define asynchronous operations
- Code & data reusability because of persisted data & Query/Mutation **Job** API
- Optimistic data support
- Lazy Loading/Fetching support
- Zero Configuration out of the box & never have to touch any Global Store
- [Flutter Hooks](https://pub.dev/packages/flutter_hooks) support out of the box

# Why?
![The hell, why?](https://media.giphy.com/media/1M9fmo1WAFVK0/giphy.gif)

The main purpose of Fl-Query is providing the easiest way to manage the messy server-state part requiring the least amount of code with code reusability & performance

Some Questions and their answers:
- **Isn't `FutureBuilder` good enough?**
  
  Yes but it is only if your commercial server has huge load of power & you're made of money or your app is simple or mostly offline & barely requires internet connection
  `FutureBuilder` isn't good for data persistency & its impossible to share data across the entire application using it. Also if you call your fetching function directly in the `build` method as `future: getData("random-id")` it'll run every time the component rebuilds & it can be mitigated only if you call the method inside `initState` which involves lots of boilerplate

- **`FutureProvider` from [riverpod](https://riverpod.dev/) or [provider](https://github.com/rrousselGit/provider) should be enough, right?**
  
  Yeah, indeed its more than enough for many applications but what if your app needs Optimistic Updates & proper server-state synchronization or simply want a custom `cacheTime`? Although `FutureProvider` is a viable solution for most of the `Future` but still you've to manually manage the cache & it still have no support for _Lazy Loading_.
  
  Remi Rousselet's riverpod is definitely an inspiration for Fl-Query & the `QueryJob` & `MutationJob` API is actually inspired by riverpod & IMO is the best state management solution any library has ever provided but that's still a client state manager just like other client state manager or synchronous data manager
