//
//  KIFTestStep+RestKit.m
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

#import "KIFTestStep+RestKit.h"
#import "RKHTTPUtilities.h"
#import "RKObjectRequestOperation.h"
#import "RKTestFactory.h"
#import "RKTestHelpers.h"
#import "RKTestFixture.h"
#import "RKLog.h"

NSString *RKStringDescribingRequestMethod(RKRequestMethod method);

// Allow assignment of Reachability status
@interface AFHTTPClient ()
@property (readwrite, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;
- (void)startMonitoringNetworkReachability;
- (void)stopMonitoringNetworkReachability;
@end

@implementation KIFTestStep (RestKit)

+ (instancetype)stepToSetSuspendedForRestKitSharedObjectManagerOperationQueue:(BOOL)suspended
{
    return [KIFTestStep stepWithDescription:[NSString stringWithFormat:@"Set `suspended` for the `operationQueue` of `[RKObjectManager sharedManager]` to %@", (suspended ? @"YES" : @"NO")] executionBlock:^KIFTestStepResult(KIFTestStep *step, NSError *__autoreleasing *error) {
        [[[RKObjectManager sharedManager] operationQueue] setSuspended:YES];
        return KIFTestStepResultSuccess;
    }];
}

+ (instancetype)stepToStubReachabilityStatusOfRestKitSharedObjectManagerHTTPClient:(AFNetworkReachabilityStatus)reachabilityStatus
{
    NSString *reachabilityStatusDescription = RKStringFromNetworkReachabilityStatus(reachabilityStatus);
    NSString *description = [NSString stringWithFormat:@"Stub the network reachability for `[RKObjectManager sharedManager].HTTPClient` to return status \"%@\"", reachabilityStatusDescription];
    return [KIFTestStep stepWithDescription:description executionBlock:^KIFTestStepResult(KIFTestStep *step, NSError *__autoreleasing *error) {
        [[[RKObjectManager sharedManager] HTTPClient] stopMonitoringNetworkReachability];
        [[RKObjectManager sharedManager] HTTPClient].networkReachabilityStatus = reachabilityStatus;
        [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingReachabilityDidChangeNotification
                                                            object:nil
                                                          userInfo:@{ AFNetworkingReachabilityNotificationStatusItem: @(reachabilityStatus) }];
        return KIFTestStepResultSuccess;
    }];
}

+ (instancetype)stepToStubRouteOfRestKitSharedObjectManagerNamed:(NSString *)routeName toPathPattern:(NSString *)pathPattern
{
    NSString *description = [NSString stringWithFormat:@"Stub the route named '%@' to point to '%@'", routeName, pathPattern];
    return [KIFTestStep stepWithDescription:description executionBlock:^(KIFTestStep *step, NSError *__autoreleasing *error) {
        [RKTestHelpers stubRouteNamed:routeName withPathPattern:pathPattern onObjectManager:nil];
        return KIFTestStepResultSuccess;
    }];
}

+ (instancetype)stepToStubRouteOfRestKitSharedObjectManagerForClass:(Class)objectClass method:(RKRequestMethod)method toPathPattern:(NSString *)pathPattern
{
    NSString *methodName = RKStringDescribingRequestMethod(method);
    NSString *description = [NSString stringWithFormat:@"Stub the route for class '%@' with method '%@' to point to '%@'", objectClass, methodName, pathPattern];
    return [KIFTestStep stepWithDescription:description executionBlock:^(KIFTestStep *step, NSError *__autoreleasing *error) {
        [RKTestHelpers stubRouteForClass:objectClass method:method withPathPattern:pathPattern onObjectManager:nil];
        
        return KIFTestStepResultSuccess;
    }];
}

+ (instancetype)stepToStubRouteOfRestKitSharedObjectManagerForRelationship:(NSString *)relationshipName ofClass:(Class)objectClass method:(RKRequestMethod)method toPathPattern:(NSString *)pathPattern
{
    NSString *methodName = RKStringDescribingRequestMethod(method);
    NSString *description = [NSString stringWithFormat:@"Stub the route for the relationship '%@' of class '%@' with method '%@' to point to '%@'", relationshipName, objectClass, methodName, pathPattern];
    return [KIFTestStep stepWithDescription:description executionBlock:^(KIFTestStep *step, NSError *__autoreleasing *error) {
        [RKTestHelpers stubRouteForRelationship:relationshipName ofClass:objectClass method:method pathPattern:pathPattern onObjectManager:nil];
        return KIFTestStepResultSuccess;
    }];
}

#pragma mark Caching Response Data

+ (instancetype)stepToCacheResponseForURLRelativeToRestKitSharedObjectManagerWithPath:(NSString *)path method:(RKRequestMethod)method responseData:(NSData *)responseData
{
    NSString *methodString = RKStringFromRequestMethod(method);
    NSString *description = [NSString stringWithFormat:@"Cache a response for a %@ request to '%@' (length: %ld)", methodString, path, (long) [responseData length]];
    return [KIFTestStep stepWithDescription:description executionBlock:^KIFTestStepResult(KIFTestStep *step, NSError *__autoreleasing *error) {
        NSURL *URL = [NSURL URLWithString:path relativeToURL:[RKObjectManager sharedManager].baseURL];
        NSDictionary *headers = [RKObjectManager sharedManager].defaultHeaders;
        [RKTestHelpers cacheResponseForURL:URL HTTPMethod:methodString headers:headers withData:responseData];
        return KIFTestStepResultSuccess;
    }];
}

+ (instancetype)stepToCacheResponseForURLRelativeToRestKitSharedObjectManagerWithPath:(NSString *)path method:(RKRequestMethod)method responseDataFromContentsOfFixtureAtPath:(NSString *)fixturePath
{
    NSData *data = [RKTestFixture dataWithContentsOfFixture:fixturePath];
    return [self stepToCacheResponseForURLRelativeToRestKitSharedObjectManagerWithPath:path method:method responseData:data];
}

#pragma mark Creating Objects via Factories

+ (instancetype)stepToCreateObjectFromRestKitFactoryWithName:(NSString *)name properties:(NSDictionary *)properties configurationBlock:(void (^)(id object))configurationBlock
{
    NSString *description = [NSString stringWithFormat:@"Create object from RestKit factory named '%@'", name];
    return [KIFTestStep stepWithDescription:description executionBlock:^(KIFTestStep *step, NSError *__autoreleasing *error) {
        id object = [RKTestFactory objectFromFactory:name properties:properties];
        KIFTestCondition(object != nil, error, @"Factory returned nil object");
        if (configurationBlock) configurationBlock(object);
        return KIFTestStepResultSuccess;
    }];
}

+ (NSArray *)stepsToCreateObjectsFromRestKitFactoriesWithNames:(NSArray *)names
{
    NSMutableArray *steps = [NSMutableArray new];
    for (NSString *name in names) {
        [steps addObject:[KIFTestStep stepToCreateObjectFromRestKitFactoryWithName:name properties:nil configurationBlock:nil]];
    }
    return steps;
}

#pragma mark Interacting with Core Data

#ifdef _COREDATADEFINES_H
+ (instancetype)stepToInsertManagedObjectInRestKitDefaultManagedObjectStoreWithEntityName:(NSString *)entityName savedToPersistentStore:(BOOL)persisted configurationBlock:(void (^)(id managedObject))configurationBlock
{
    NSString *description = [NSString stringWithFormat:@"Insert a Managed Object for Entity '%@' into `[RKManagedObjectStore defaultStore]`%@", entityName, (persisted ? @" and save it to the persistent store" : @"")];
    return [KIFTestStep stepWithDescription:description executionBlock:^(KIFTestStep *step, NSError *__autoreleasing *error) {
        NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        KIFTestCondition(managedObjectContext, error, @"Cannot instantiate a managed object without core data configured");
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
        KIFTestCondition(managedObjectContext, error, @"Could not retrieve entity with name '%@'", entityName);
        __block BOOL success;
        [managedObjectContext performBlockAndWait:^{
            NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
            if (configurationBlock) configurationBlock(object);
            success = (persisted) ? [managedObjectContext saveToPersistentStore:error] : [managedObjectContext save:error];
            if (! success) {
                RKLogCoreDataError(*error);
            }
        }];
        KIFTestCondition(success, error, @"Failed to save managed object context: %@", [*error localizedDescription]);
        
        return KIFTestStepResultSuccess;
    }];
}

+ (instancetype)stepToDeleteAllManagedObjectsInRestKitDefaultManagedObjectStoreWithEntityName:(NSString *)entityName
{
    NSString *description = entityName ? [NSString stringWithFormat:@"Delete all Managed Objects for the '%@' Entity from `[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext`", entityName]
    : @"Delete all Managed Objects from `[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext`";
    return [KIFTestStep stepWithDescription:description executionBlock:^KIFTestStepResult(KIFTestStep *step, NSError *__autoreleasing *error) {
        NSArray *entities = entityName ? @[ [[RKManagedObjectStore defaultStore].managedObjectModel entitiesByName][entityName] ] : [RKManagedObjectStore defaultStore].managedObjectModel.entities;
        for (NSEntityDescription *entity in entities) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
            NSArray *managedObjects = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:nil];
            for (NSManagedObject *managedObject in managedObjects) {
                [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext deleteObject:managedObject];
            }
        }
        
        return KIFTestStepResultSuccess;
    }];
}

+ (instancetype)stepToPerformBlockAndSaveMainQueueManagedObjectContextOfRestKitDefaultManagedObjectStore:(void(^)(NSManagedObjectContext *managedObjectContext, BOOL *saveToPersistentStore))block
{
    return [KIFTestStep stepWithDescription:@"Perform a block and save `[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext`" executionBlock:^KIFTestStepResult(KIFTestStep *step, NSError *__autoreleasing *error) {
        NSAssert([RKManagedObjectStore defaultStore], @"You must initialize Core Data");
        NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        __block BOOL saveToPersistentStore = NO;
        [managedObjectContext performBlockAndWait:^{
            if (block) block(managedObjectContext, &saveToPersistentStore);
        }];
        
        BOOL success = (saveToPersistentStore) ? [managedObjectContext saveToPersistentStore:error] : [managedObjectContext save:error];
        if (! success) { RKLogCoreDataError(*error); }
        return success ? KIFTestStepResultSuccess : KIFTestStepResultFailure;
    }];
}
#endif

@end

@implementation KIFTestStep (ViewControllers)

static Class KIFTestStepDefaultNavigationBarClass = nil;
static Class KIFTestStepDefaultToolbarBarClass = nil;

+ (void)setDefaultNavigationBarClass:(Class)navigationBarClass
{
    KIFTestStepDefaultNavigationBarClass = navigationBarClass;
}

+ (void)setDefaultToolbarClass:(Class)toolbarClass
{
    KIFTestStepDefaultToolbarBarClass = toolbarClass;
}

+ (id)stepToPresentViewControllerWithClass:(Class)viewControllerClass withinNavigationControllerWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
                        configurationBlock:(void (^)(id viewController))configurationBlock
{
    Class navigationBarClassToUse = navigationBarClass ?: KIFTestStepDefaultNavigationBarClass;
    Class toolbarClassToUse = toolbarClass ?: KIFTestStepDefaultToolbarBarClass;
    NSString *description = [NSString stringWithFormat:@"Presents view controller with Class '%@' in Navigation Controller with Navigation Bar Class '%@' and Toolbar Class '%@'", viewControllerClass, navigationBarClassToUse, toolbarClassToUse];
    return [KIFTestStep stepWithDescription:description executionBlock:^(KIFTestStep *step, NSError **error) {
        UIViewController *viewControllerToPresent = [viewControllerClass new];
        KIFTestCondition(viewControllerToPresent != nil, error, @"Expected a view controller, but got nil");
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithNavigationBarClass:navigationBarClassToUse toolbarClass:toolbarClassToUse];
        navigationController.viewControllers = @[viewControllerToPresent];
        if (configurationBlock) configurationBlock(viewControllerToPresent);
        [UIApplication sharedApplication].keyWindow.rootViewController = navigationController;
        
        return KIFTestStepResultSuccess;
    }];
}

@end
