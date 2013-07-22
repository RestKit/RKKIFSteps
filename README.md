RKKIFSteps
==========

**Steps for integrating RestKit with the KIF (Keep It Functional) testing library from Square**

RKKIFSteps is a package of steps for [KIF](https://github.com/square/KIF) that provide very convenient testing facilities for applications built with [RestKit](http://github.com/RestKit/RestKit). The steps are designed to enable a very specific, highly productive test-driven workflow to applications that embrace the testing methodology around which they are built.

Note that they steps assume competency with RestKit, KIF, and a familiarity with the RestKit testing classes. It is recommended that you review the [RestKit Testing Documentation](https://github.com/RestKit/RestKit/wiki/Unit-Testing-with-RestKit) before diving into the steps.

## Testing Philosophy

To get the most out of RKKIFSteps it is necessary to understand the testing methodology advocated by the package. The key points are:

1. Tests are executed against a local test server that returns stubbed responses. Testing against a live server is slow, error prone and creates undesirable dependencies between backend server development and iOS client development. Use of a local test server enables full-stack testing of the asynchronous HTTP request/response cycle with millisecond response times and avoids iOS development from becoming blocked by unfinished server development.
1. Coordination between the client and server is facilitated by the use of JSON fixtures that represent expected request and response combinations.
1. Tests are to be isolated from one another. Each test scenario should do a complete setup and tear down of any application state necessary to run the scenario such that all scenarios can be run in isolation and individual failures do not cascade across the suite.
1. Test scenarios will use RestKit's router to alter application behavior. This implies that the application under test leverages RestKit's routing functionality to generate URL's rather than directly specifying paths.
1. The application under test is interacting with a single remote API using a singleton instance of `RKObjectManager` that is available via the `[RKObjectManager sharedManager]` method.

If your application aligns with these assumptions, then RKKIFSteps provides an excellent set of tools for testing your app from a user perspective.

## Features

### Stubbing Network Interactions

By far the most important feature of RKKIFSteps is the support for stubbing network interactions. The steps make changes the [`RKRouteSet`](http://restkit.org/api/latest/Classes/RKRouteSet.html) of the `[RKObjectManager sharedManager]` instance such that within each test scenario you can change the outcome of particular network interactions. This is achieved primarilly by changing the `pathPattern` of a given route such that it results in an alternate response being returned by the testing server.

For example, consider the following table of possible changes for a theoretical view controller in an app that performs a `POST` request that creates a new `Review` object for a `Restaurant` entity with the ID of 12345:

| Original Path Pattern      | New Pattern | HTTP Status Code            | Response Body  |
| ---------------------------|-------------|-----------------------------|--------------------------------------------------------------|
| /restaurants/12345/reviews | /review     | 201 (Created)               | { "id": 1, "title": "Whatever"}                              |
| /restaurants/12345/reviews | /422        | 422 (Unprocessable Entity)  | { "errors": { "code": 12345, "message": "Invalid object." }} |
| /restaurants/12345/reviews | /500        | 500 (Internal Server Error) | ""                                                           |
| /restaurants/12345/reviews | /503        | 503 (Service Unavailable)   | <html>Service unavailable.</html>                            |

By making simple changes to the routing table in the body of our KIF scenarios, we can now trivially test the following scenarios:

1. What happens when POST'ing a Review succeeds
2. What happens when POST'ing a Review is rejected by the server with an error
3. What happens when POST'ing a Review and the server raises an exception during processing
4. What happens when POST'ing a Review and the server is offline

Aside from the simplicity of this workflow there are several accessory benefits:

1. The tests execute full stack. Requests are made asynchronously and processed by RestKit, ensuring that the entire system is executing properly.
2. Object mapping is performed on the responses returned, ensuring that your test fixtures match the mappings in use by the app.
3. Tests execute very quickly because their is no server-side processing taking place.

#### Step Overview

Each step below manipulates the `[RKObjectManager sharedManager].router.routeSet` object when executed. In order to ensure isolation between scenarios be sure to read the [Setup and Tear Down Steps section](#setup-and-tear-down-steps) of this document.

1. [`stepToStubRouteOfRestKitSharedObjectManagerForClass:method:toPathPattern:`]() stubs a [class route](http://restkit.org/api/latest/Classes/RKRoute.html#//api/name/routeWithClass:pathPattern:method:) identified by object class and HTTP method to return a new path pattern.
2. [`stepToStubRouteOfRestKitSharedObjectManagerForRelationship:ofClass:method:toPathPattern:`]() stubs a [relationship route](http://restkit.org/api/latest/Classes/RKRoute.html#//api/name/routeWithRelationshipName:objectClass:pathPattern:method:) identified by object class, relationship name and HTTP method to return a new path pattern.
3. [`stepToStubRouteOfRestKitSharedObjectManagerNamed:toPathPattern:`]() stubs a [named route](http://restkit.org/api/latest/Classes/RKRoute.html#//api/name/routeWithName:pathPattern:method:) identified by name return a new path pattern.
4. [`stepToSetSuspendedForRestKitSharedObjectManagerOperationQueue:`]() sets the `suspended` property for the `[RKObjectManager sharedManager].operationQueue` to the given value.
4. [`stepToStubReachabilityStatusOfRestKitSharedObjectManagerHTTPClient:`]() stubs the `networkReachabilityStatus` property for the `[RKObjectManager sharedManager].HTTPClient` to return the given value and emits a reachability change notification, simulating transition between network reachability states.

### Caching Response Data

There are a pair of steps available for injecting data into the `NSURLCache`. Both steps work by constructing `NSCachedURLResponse` objects that are relative to the `baseURL` of the `[RKObjectManager sharedManager]`.

1. [`stepToCacheResponseForURLRelativeToRestKitSharedObjectManagerWithPath:method:responseData:`]() - Constructs and caches a response for the given path and HTTP method with the specified `NSData` as the response body.
1. [`stepToCacheResponseForURLRelativeToRestKitSharedObjectManagerWithPath:method:responseDataFromContentsOfFixtureAtPath:`]() - Constructs and caches a response for the given path and HTTP method with the response body read from a fixture stored in the fixture bundle.

### Creating Objects via Factories

The RestKit testing factories include a lightweight, block based object factory API to aid in creating test data. There are several steps available for leveraging the factories in your scenarios:

1. [`stepToCreateObjectFromRestKitFactoryWithName:properties:configurationBlock:`]() - Invokes the factory with given name, optionally setting a dictionary of properties on the constructed object, and then yielding the new object to the block for further processing. The constructed object can then be assigned to a controller for subsequent interaction in the UI.
2. [`stepsToCreateObjectsFromRestKitFactoriesWithNames:`]() - Returns an array of `KIFTestStep` objects for creating objects via multiple factory invocations. This step is most useful with Core Data objects, as the created objects are not yielded for processing.

### Interacting with Core Data

There are a few steps available for working with Core Data:

1. [`stepToInsertManagedObjectInRestKitDefaultManagedObjectStoreWithEntityName:savedToPersistentStore:configurationBlock:`]() - Inserts a new managed object for the specified entity into the `[RKManagedObjectStore defaultStore]` and yields it for further processing, optionally saving it to the persistent store when the configuration block has completed.
2. [`stepToDeleteAllManagedObjectsInRestKitDefaultManagedObjectStoreWithEntityName:`]() - Deletes all managed objects from the default store for the specified entity. If the given entity name is `nil`, then all managed objects for all entities are deleted.
3. [`stepToPerformBlockAndSaveMainQueueManagedObjectContextOfRestKitDefaultManagedObjectStore:`]() - Performs a block within the `[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext` and then saves the context, optionally back to the persistent store.

## Setup and Tear Down Steps

RKKIFSteps is designed to be used in KIF environment in which test scenarios are as isolated from one another as possible. To ensure isolation, you must you configure a set of default steps to set up and tear down the environment by resetting the test factories, recreating the RestKit singleton objects, clearing the `rootViewController` of the main window, and performing any application specific reset logic necessary for your app. Here's a compehensive example of what your setup and tear down steps may look like. Note that in this example the test test factory has been used to share setup logic between unit and integration tests. Both `KIFTestScenario` and `RKTestFactory` are extended via categories.

```objc
@interface KIFTestScenario (Example)
@end

@implementation KIFTestScenario (Example)

+ (void)load
{
    [KIFTestScenario setDefaultStepsToSetUp:@[ [KIFTestStep stepToSetUp] ]];
    [KIFTestScenario setDefaultStepsToTearDown:@[ [KIFTestStep stepToTearDown] ]];
}

@end

@interface KIFTestStep (ExampleSteps)
@end

@implementation KIFTestStep (ExampleSteps)

+ (id)stepToSetUp
{
    return [KIFTestStep stepWithDescription:@"Set Up the Test Environment" executionBlock:^(KIFTestStep *step, NSError **error) {
        NSException *caughtException = nil;
        @try {
            // Clear the root view controller
            id rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            if ([rootViewController isKindOfClass:[UINavigationController class]]) [rootViewController setViewControllers:nil];
            UIViewController *newRootViewController = [[UIViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newRootViewController];
            [UIApplication sharedApplication].keyWindow.rootViewController = navigationController;

            /**
             NOTE: Set up of the KIF testing environment has been centralized into the `[RKTestFactory setUp]` method so that the logic may be shared between unit and integration tests. If you need to make non user-interface specific environment configuration changes, please make them in the test factory.
             */
            [RKTestFactory setUp];
        }
        @catch (NSException *exception) {
            caughtException = exception;
        }

        KIFTestCondition(caughtException == nil, error, @"Caught exception during set up: %@", caughtException);
        return KIFTestStepResultSuccess;
    }];
}

+ (id)stepToTearDown
{
    return [KIFTestStep stepWithDescription:@"Tear Down the Test Environment" executionBlock:^(KIFTestStep *step, NSError **error) {
        NSDictionary *envVars = [[NSProcessInfo processInfo] environment];
        if ([envVars[@"KIF_SKIP_TEAR_DOWN"] isNotBlank]) return KIFTestStepResultSuccess;

        NSException *caughtException = nil;
        @try {
            /**
             NOTE: Tear down of the KIF testing environment has been centralized into the `[RKTestFactory tearDown]` method so that the logic may be shared between unit and integration tests. If you need to make non user-interface specific environment configuration changes, please make them in the test factory.
             */
            [RKTestFactory tearDown];
        }
        @catch (NSException *exception) {
            caughtException = exception;
        }

        KIFTestCondition(caughtException == nil, error, @"Caught exception during set up: %@", caughtException);
        return KIFTestStepResultSuccess;
    }];
}

@end

@interface RKTestFactory (ExampleFactories)
@end

@implementation RKTestFactory (ExampleFactories)

// NOTE: `EAObjectManager` is our application specific object manager subclass and `EAManagedObjectStore` is our application specific object store subclass
+ (void)load
{
    NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"org.restkit.RKKIFStepsUnitTests"];
    if (testBundle) {
        // Unit Tests
        [RKTestFixture setFixtureBundle:testBundle];
    } else {
        // KIF
        [RKTestFixture setFixtureBundle:[NSBundle mainBundle]];
    }

    // Configure our logging level
    RKLogConfigureFromEnvironment();

    [self setBaseURL:[NSURL URLWithString:GateGuruDefaultBaseURLString]];

    [self setSetupBlock:^{
        // Setup shared instances
        EAObjectManager *objectManager = [RKTestFactory objectManager];
        [RKObjectManager setSharedManager:objectManager];
        [RKManagedObjectStore setDefaultStore:objectManager.managedObjectStore];
    }];

    [self setTearDownBlock:^{
        EAObjectManager *objectManager = [EAObjectManager sharedManager];
        [objectManager.operationQueue cancelAllOperations];

        // Delete all managed objects from the store
        EAManagedObjectStore *managedObjectStore = [EAManagedObjectStore defaultStore];
        if (managedObjectStore) {
            managedObjectStore.managedObjectCache = nil;
            managedObjectStore.mainQueueManagedObjectContext = nil;
            NSManagedObjectContext *managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
            [managedObjectContext performBlockAndWait:^{
                NSError *error = nil;
                for (NSEntityDescription *entity in managedObjectStore.managedObjectModel) {
                    NSFetchRequest *fetchRequest = [NSFetchRequest new];
                    [fetchRequest setEntity:entity];
                    NSError *error = nil;
                    NSArray *objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
                    for (NSManagedObject *object in objects) {
                        [managedObjectContext deleteObject:object];
                    }
                }
                [managedObjectContext save:&error];
                [managedObjectContext processPendingChanges];
            }];
        }

        [EAManagedObjectStore setDefaultStore:nil];
    }];
}

@end
```

### Core Data Considerations

If your app is backed by Core Data persistence then several other factors should be considered in your tests:

1. Use an in-memory store or ensure that all objects have been deleted from your persistent store in between tests. This prevents objects from leaking across test and interfering with assertions
2. Ensure that all in progress `RKManagedObjectRequestOperation` instances have been fully cancelled. If you tear down the store before an operation completes then you can encounter crashes during testing.
3. Keep in mind that objects inserted into the store will be visible via fetches.

## Example App

An example app is forthcoming.

## Contact

Blake Watters

- http://github.com/blakewatters
- http://twitter.com/blakewatters
- blakewatters@gmail.com

## License

RKKIFSteps is available under the Apache 2 License. See the LICENSE file for more info.
