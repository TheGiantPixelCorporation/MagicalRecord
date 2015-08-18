//
//  NSDictionary+MagicalDataImport.m
//  Magical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "NSObject+MagicalDataImport.h"
#import "NSAttributeDescription+MagicalDataImport.h"
#import "NSEntityDescription+MagicalDataImport.h"
#import "NSManagedObject+MagicalDataImport.h"
#import "NSRelationshipDescription+MagicalDataImport.h"
#import "MagicalRecordLogging.h"

NSUInteger const kMagicalRecordImportMaximumAttributeFailoverDepth = 10;


@implementation NSObject (MagicalRecord_DataImport)

- (NSString *) MR_lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo;
{
    return [self MR_lookupKeyHelper:attributeInfo keyName:kMagicalRecordImportAttributeKeyMapKey];
}

- (id) MR_valueForAttribute:(NSAttributeDescription *)attributeInfo
{
    NSString *lookupKey = [self MR_lookupKeyForAttribute:attributeInfo];
    return lookupKey ? [self valueForKeyPath:lookupKey] : nil;
}

- (NSString *) MR_lookupKeyForRelationshipImport:(NSRelationshipDescription *)relationshipInfo {
    return [self MR_lookupKeyHelper:relationshipInfo keyName:kMagicalRecordImportRelationshipMapKey];
}

- (NSString *)MR_lookupKeyHelper:(NSPropertyDescription *)propertyInfo
                         keyName:(NSString *)mapKeyName  {
    NSString *propertyName = [propertyInfo name];
    NSString *lookupKey = [[propertyInfo userInfo] valueForKey:mapKeyName] ?: propertyName;
    
    id value = [self valueForKeyPath:lookupKey];
    
    for (NSUInteger i = 0; i < kMagicalRecordImportMaximumAttributeFailoverDepth && value == nil; i++)
    {
        propertyName = [NSString stringWithFormat:@"%@.%lu", mapKeyName, (unsigned long)i];
        lookupKey = [[propertyInfo userInfo] valueForKey:propertyName];
        if (lookupKey == nil)
        {
            return nil;
        }
        value = [self valueForKeyPath:lookupKey];
    }
    
    return value != nil ? lookupKey : nil;
    
}

- (NSString *) MR_lookupKeyForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSEntityDescription *destinationEntity = [relationshipInfo destinationEntity];
    if (destinationEntity == nil) 
    {
        MRLogError(@"Unable to find entity for type '%@'", [self valueForKey:kMagicalRecordImportRelationshipTypeKey]);
        return nil;
    }
    
    NSString               *primaryKeyName      = [relationshipInfo MR_primaryKey];
    NSAttributeDescription *primaryKeyAttribute = [destinationEntity MR_attributeDescriptionForName:primaryKeyName];
    NSString               *lookupKey           = [self MR_lookupKeyForAttribute:primaryKeyAttribute] ?: [primaryKeyAttribute name];

    return lookupKey;
}

- (id) MR_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSString *lookupKey = [self MR_lookupKeyForRelationship:relationshipInfo];
    return lookupKey ? [self valueForKeyPath:lookupKey] : nil;
}

@end
