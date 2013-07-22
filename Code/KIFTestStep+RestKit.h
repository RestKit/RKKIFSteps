//
//  KIFTestStep+RestKit.h
//  RestKit
//
//  Created by Blake Watters on 7/1/13.
//  Copyright (c) 2009-2013 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "KIFTestStep.h"
#import <RestKit/RestKit.h>

/**
 The `RestKit` category provides a number of steps to aid in testing RestKit based applications using the KIF integration testing library.
 */
@interface KIFTestStep (RestKit)

///------------------------------------
/// @name Stubbing Network Interactions
///------------------------------------

/**
 Creates and returns a KIF test step that sets the `suspended` property on `[RKObjectManager sharedManager].operationQueue` to the given value.
 
 @param suspended A Boolean value specifying if the queue should be set to suspended or not.
 @return A KIF test step for setting the value of the suspended property for the operation queue of the RestKit shared object manager instance.
 */
+ (instancetype)stepToSetSuspendedForRestKitSharedObjectManagerOperationQueue:(BOOL)suspended;

/**
 Creates and returns a KIF test step that stubs the value of the `networkReachabilityStatus` property on `[RKObjectManager sharedManager].HTTPClient` to the given value and emits a notification that network reachability state has transitioned to the given value. This step is commonly used to test offline mode or application behavior during network availability transitions.
 
 @param reachabilityStatus An `AFNetworkReachabilityStatus` value for the desired reachability state to stub on the HTTP client of the shared manager.
 @return A KIF test step for stubbing the value of the network reachability status property for the HTTP client of the RestKit shared object manager instance.
 */
+ (instancetype)stepToStubReachabilityStatusOfRestKitSharedObjectManagerHTTPClient:(AFNetworkReachabilityStatus)reachabilityStatus;

/**
 Creates and returns a KIF test step that stubs a named route registered on `[RKObjectManager sharedManager].router.routeSet` to return a new path pattern.
 
 @param routeName The name of the route to be stubbed.
 @param pathPattern The new path pattern value to be used by the specified route.
 @return A KIF test step for stubbing the path pattern of a named route registered on the RestKit shared object manager instance.
 */
+ (instancetype)stepToStubRouteOfRestKitSharedObjectManagerNamed:(NSString *)routeName toPathPattern:(NSString *)pathPattern;

/**
 Creates and returns a KIF test step that that stubs a class route registered on `[RKObjectManager sharedManager].router.routeSet` to return a new path pattern.
 
 @param objectClass The class of the route to be stubbed.
 @param method The exact method bitmask value of the route to be stubbed.
 @param pathPattern The new path pattern value to be used by the specified route.
 @return A KIF test step for stubbing the path pattern of a class route registered on the RestKit shared object manager instance.
 */
+ (instancetype)stepToStubRouteOfRestKitSharedObjectManagerForClass:(Class)objectClass method:(RKRequestMethod)method toPathPattern:(NSString *)pathPattern;

/**
 Creates and returns a KIF test step that stubs a relationship route registered on `[RKObjectManager sharedManager].router.routeSet` to return a new path pattern.
 
 @param objectClass The class of the route to be stubbed.
 @param method The exact method bitmask value of the route to be stubbed.
 @param pathPattern The new path pattern value to be used by the specified route.
 @return A KIF test step for stubbing the path pattern of a relationship route registered on the RestKit shared object manager instance.
 */
+ (instancetype)stepToStubRouteOfRestKitSharedObjectManagerForRelationship:(NSString *)relationshipName ofClass:(Class)objectClass method:(RKRequestMethod)method toPathPattern:(NSString *)pathPattern;

///----------------------------
/// @name Caching Response Data
///----------------------------

/**
 Creates and returns a KIF test step that caches a response for a URL with the given path relative to `[RKObjectManager sharedManager].baseURL` for the specified HTTP method that will return the specified response data.
 
 @param path A relative path for constructing the destination URL.
 @param method A single, specific request method for requests to the URL that should load the cached response (i.e. `RKRequestMethodGET`).
 @param responseData The data to be stored as the body of the cached response.
 @return A KIF test step that caches the specified response.
 */
+ (instancetype)stepToCacheResponseForURLRelativeToRestKitSharedObjectManagerWithPath:(NSString *)path method:(RKRequestMethod)method responseData:(NSData *)responseData;

/**
 Creates and returns a KIF test step that caches a response for a URL with the given path relative to `[RKObjectManager sharedManager].baseURL` for the specified HTTP method that will return response data loaded from the fixture at the specified path.
 
 @param path A relative path for constructing the destination URL.
 @param method A single, specific request method for requests to the URL that should load the cached response (i.e. `RKRequestMethodGET`).
 @param fixturePath A path to a response fixture stored within the designated fixture bundle that is to be used when populating the cached response.
 @return A KIF test step that caches the specified response.
 */
+ (instancetype)stepToCacheResponseForURLRelativeToRestKitSharedObjectManagerWithPath:(NSString *)path method:(RKRequestMethod)method responseDataFromContentsOfFixtureAtPath:(NSString *)fixturePath;

///-------------------------------------
/// @name Creating Objects via Factories
///-------------------------------------

/**
 Creates and returns a KIF test step that will create an object from the RestKit factory with the given name, optionally setting a dictionary of property values on the constructed object and yielding it to a configuration block for further processing.
 
 @param name The name of the RestKit factory construct the object from.
 @param properties A dictionary of property values to assign to the constructed object.
 @param configurationBlock An optional block to yield the constructed object to for configuration.
 @return A KIF test step that creates an object from a RestKit factory.
 */
+ (instancetype)stepToCreateObjectFromRestKitFactoryWithName:(NSString *)name properties:(NSDictionary *)properties configurationBlock:(void (^)(id object))configurationBlock;

/**
 Creates and returns a KIF test step that will create an arbitrary number of objects from a list of named factories.
 
 @param names An array of strings that specify the names of RestKit factories that should be invoked to create objects.
 @return An array of `KIFTestStep` objects that create objects via RestKit factories.
 */
+ (NSArray *)stepsToCreateObjectsFromRestKitFactoriesWithNames:(NSArray *)names;

///---------------------------------
/// @name Interacting with Core Data
///---------------------------------

#ifdef _COREDATADEFINES_H
/**
 Creates and returns a KIF test step that will insert a new `NSManagedObject` instance for the entity with the given name into `[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext`, optionally yielding it to a block for further configuration and saving it to the persistent store.
 
 @param entityName The entity for the newly inserted managed object.
 @param persisted Whether or not the newly inserted object should be saved to the persistent store.
 @param configurationBlock An optional block to yield the constructed object to for configuration.
 @return A KIF test step that inserts an object into the default managed object store.
 */
+ (instancetype)stepToInsertManagedObjectInRestKitDefaultManagedObjectStoreWithEntityName:(NSString *)entityName savedToPersistentStore:(BOOL)persisted configurationBlock:(void (^)(id managedObject))configurationBlock;

/**
 Creates and returns a KIF test step that will delete all managed objects for the entity with the given name from `[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext`.
 
 @param entityName The name of the entity to delete all managed objects of. If `nil`, then all managed objects will be deleted.
 @return A KIF test step that deletes managed objects from the default managed object store.
 */
+ (instancetype)stepToDeleteAllManagedObjectsInRestKitDefaultManagedObjectStoreWithEntityName:(NSString *)entityName;

/**
 Creates and returns a KIF test step that will perform a block within the `[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext` and save the context, optionally back to the persistent store.
 
 @param block A block to be executed within the managed object context. It accepts two arguments: the managed object context itself and a pointer to a Boolean value that determines if the subsequent save of the managed object context will be back to the persistent store. The block can be `nil` if you only wish to trigger a save. The default value of `saveToPersistentStore` is `NO`.
 */
+ (instancetype)stepToPerformBlockAndSaveMainQueueManagedObjectContextOfRestKitDefaultManagedObjectStore:(void(^)(NSManagedObjectContext *managedObjectContext, BOOL *saveToPersistentStore))block;

#endif

@end

@interface KIFTestStep (ViewControllers)

/**
 Sets the default `UINavigationBar` subclass to use when presenting view controllers without a navigation bar class specified.
 
 @param navigationBarClass A subclass of `UINavigationBar` to use when presenting view controllers via `stepToPresentViewControllerWithClass:withinNavigationControllerWithNavigationBarClass:toolbarClass:configurationBlock:` when the `navigationBarClass` argument is `nil`.
 */
+ (void)setDefaultNavigationBarClass:(Class)navigationBarClass;

/**
 Sets the default `UIToolbar` subclass to use when presenting view controllers without a toolbar bar class specified.
 
 @param toolbarClass A subclass of `UIToolbar` to use when presenting view controllers via `stepToPresentViewControllerWithClass:withinNavigationControllerWithNavigationBarClass:toolbarClass:configurationBlock:` when the `toolbarClass` argument is `nil`.
 */
+ (void)setDefaultToolbarClass:(Class)toolbarClass;

/**
 Creates and returns a KIF test step that will instantiate and present an instance of the specified `UIViewController` subclass within a `UINavigationController` instance with the specified `UINavigationBar` and `UIToolbar` subclasses, optionally yielding the instantiated controller to the block for configuration.
 
 @param viewControllerClass The `UIViewController` subclass to instantiate.
 @param navigationBarClass A subclass of `UINavigationBar` to use when instantiating the `UINavigationController` instance within which the view controller instance will be presented. If `nil`, then the class specified via `setDefaultNavigationBarClass:` will be used.
 @param toolbarClass A subclass of `UIToolbar` to use when instantiating the `UINavigationController` instance within which the view controller instance will be presented. If `nil`, then the class specified via `setDefaultToolbarClass:` will be used.
 @param configurationBlock An optional block in which to yield the newly instantiated view controller instance prior to presenting it in the main window.
 */
+ (instancetype)stepToPresentViewControllerWithClass:(Class)viewControllerClass withinNavigationControllerWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
                        configurationBlock:(void (^)(id viewController))configurationBlock;
@end
