/*
  Forceea data factory (v2.5)
  Copyright (C) 2021 Nikos Mitrakis

  This program is free software: you can redistribute it and/or modify it under the terms
  of the GNU General Public License as published by the Free Software Foundation,
  either version 3 of the License, or any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU General Public License for more details.

  You can find a copy of the GNU General Public License at
  https://github.com/Forceea/Forceea-data-factory/blob/master/LICENSE
*/
@IsTest
public class FObjectAsyncTest {
    private static final Integer FOBJECT1_NUM_RECORDS = 10;
    private static final Integer FOBJECT2_NUM_RECORDS = 10;
    private static final String PARTITION_FIELD_VALUE = 'df';

    @IsTest
    private static void insertRecords_maxIterationsPerBatchDefault_expectSuccess() {
        Integer maxIterationsPerBatch = 0;
        Integer numIterations = 10;
        Integer numJobs = 2;
        Map<String, FObject> template = template1();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        List<FObjectOne__c> records = [SELECT Id FROM FObjectOne__c];
        Boolean resultIsValid = FObjectAsync.processIsValid() &&
            (records.size() == 1 * numJobs * FOBJECT1_NUM_RECORDS);
        System.assert(resultIsValid, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_maxIterationsPerBatch1_expectSuccess() {
        Integer maxIterationsPerBatch = 1;
        Integer numIterations = 10;
        Integer numJobs = 2;
        Map<String, FObject> template = template1();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        List<FObjectOne__c> records = [SELECT Id FROM FObjectOne__c];
        Boolean resultIsValid = FObjectAsync.processIsValid() &&
            (records.size() == maxIterationsPerBatch * numJobs * FOBJECT1_NUM_RECORDS);
        System.assert(resultIsValid, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_maxIterationsPerBatch5_expectSuccess() {
        Integer maxIterationsPerBatch = 5;
        Integer numIterations = 100;
        Integer numJobs = 2;
        Map<String, FObject> template = template1();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .shouldBenchmark(false)
            .insertRecords();
        Test.stopTest();

        List<FObjectOne__c> records = [SELECT Id FROM FObjectOne__c];
        Boolean resultIsValid = FObjectAsync.processIsValid() &&
            (records.size() == maxIterationsPerBatch * numJobs * FOBJECT1_NUM_RECORDS);
        System.assert(resultIsValid, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_maxIterationsPerBatchNotSet_expectSuccess() {
        Integer maxIterationsPerBatch = -999;
        Integer numIterations = 10;
        Integer numJobs = 1;

        Test.startTest();
        getFObjectAsync(template1(), maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        List<FObjectOne__c> records = [SELECT Id FROM FObjectOne__c];
        Boolean resultIsValid = FObjectAsync.processIsValid() && (records.isEmpty());
        System.assert(resultIsValid, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_invalidDefinitionWithBenchmark_expectFailure() {
        Integer maxIterationsPerBatch = 5;
        Integer numIterations = 100;
        Integer numJobs = 2;
        Map<String, FObject> template = template1Invalid();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        System.assert(!FObject.processIsValid(), 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_invalidDefinitionWithoutBenchmark_expectFailure() {
        Integer maxIterationsPerBatch = 5;
        Integer numIterations = 100;
        Integer numJobs = 2;
        Map<String, FObject> template = template1Invalid();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .shouldBenchmark(false)
            .insertRecords();
        Test.stopTest();

        System.assert(!FObject.processIsValid(), 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_seed_expectSuccess() {
        Integer maxIterationsPerBatch = 1;
        Integer numIterations = 10;
        Integer numJobs = 2;

        Map<String, FObject> template = new Map<String, FObject>{
            'FObjectTwos' => new FObject('FObjectTwo__c')
                .setNumberOfRecords(FOBJECT2_NUM_RECORDS)
                .setDefinition(FObjectTwo__c.TestPicklistDRequired__c, 'random type(picklist)')
                .setPartitionFieldName(FObjectTwo__c.ForceeaPartition__c)
                .setDefinition(FObjectTwo__c.TestText__c, 'random type(number) from(10) to(100) scale(0)')
        };
        FObject.setSeed(0);

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, 'df')
            .insertRecords();
        Test.stopTest();

        List<FObjectTwo__c> records1 = [
            SELECT TestText__c
            FROM FObjectTwo__c
            WHERE ForceeaPartition__c = 'df1'
            ORDER BY TestText__c
        ];
        List<FObjectTwo__c> records2 = [
            SELECT TestText__c
            FROM FObjectTwo__c
            WHERE ForceeaPartition__c = 'df2'
            ORDER BY TestText__c
        ];
        Integer errors = 0;
        Integer counter = 0;
        for (FObjectTwo__c record : records2) {
            if (record.TestText__c == records1.get(counter).TestText__c) {
                errors++;
            }
            counter++;
        }

        System.assert(FObjectAsync.processIsValid() & errors == 0, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_setRequiredFieldsTrue_expectSuccess() {
        Integer maxIterationsPerBatch = 1;
        Integer numIterations = 10;
        Integer numJobs = 1;

        Test.startTest();
        getFObjectAsync(templateSetRequiredFields(), maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        System.assert(FObjectAsync.processIsValid(), 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_setRequiredFieldsFalse_expectFailure() {
        Integer maxIterationsPerBatch = 1;
        Integer numIterations = 10;
        Integer numJobs = 1;

        Test.startTest();
        getFObjectAsync(templateWithoutRequiredFields(), maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        System.assert(!FObjectAsync.processIsValid(), 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_variables_expectSuccess() {
        Integer maxIterationsPerBatch = 0;
        Integer numIterations = 10;
        Integer numJobs = 2;
        FObject.setGlobalVariable('globalVar', 'global');
        Map<String, FObject> template = templateVariables();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        Integer errors = 0;
        List<FObjectOne__c> records = [SELECT TestText__c FROM FObjectOne__c];
        for (FObjectOne__c record : records) {
            if (record.TestText__c != 'local - global') {
                errors++;
                break;
            }
        }
        Boolean resultIsValid = (errors == 0) && (records.size() == 1 * numJobs * FOBJECT1_NUM_RECORDS);
        System.assert(resultIsValid, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_verboseNone_expectSuccess() {
        Integer maxIterationsPerBatch = 0;
        Integer numIterations = 10;
        Integer numJobs = 2;
        FObject.setGlobalVerbose('none'); // DO NOT REMOVE
        Map<String, FObject> template = template3();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        Integer errors = 0;
        List<String> debugLogs = FObject.getGlobalDebugLogs();

        if (debugLogs.contains('- Definition [static value(test)] of [TestText__c] is valid.') ||
            debugLogs.contains('Will insert the created records of [FObjectOne__c].')) {
            errors++;
        }

        System.assert(errors == 0, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_verboseInfo_expectSuccess() {
        Integer maxIterationsPerBatch = 0;
        Integer numIterations = 10;
        Integer numJobs = 2;
        FObject.setGlobalVerbose('info'); // DO NOT REMOVE
        Map<String, FObject> template = template3();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        Integer errors = 0;
        List<String> debugLogs = FObject.getGlobalDebugLogs();

        if (debugLogs.contains('- Definition [static value(test)] of [TestText__c] is valid.') ||
            debugLogs.contains('Will insert the created records of [FObjectOne__c].')) {
            errors++;
        }

        System.assert(errors == 0, 'insertRecords - errors found');
    }

    @IsTest
    private static void insertRecords_verboseDebug_expectSuccess() {
        Integer maxIterationsPerBatch = 0;
        Integer numIterations = 10;
        Integer numJobs = 1;
        FObject.setGlobalVerbose('debug'); // DO NOT REMOVE
        Map<String, FObject> template = template3();

        Test.startTest();
        getFObjectAsync(template, maxIterationsPerBatch, numIterations, numJobs, PARTITION_FIELD_VALUE)
            .insertRecords();
        Test.stopTest();

        Integer errors = 0;
        List<String> debugLogs = FObject.getGlobalDebugLogs();

        if (!debugLogs.contains('- Definition [static value(test)] of [TestText__c] is valid with ID [wiaeQ1].')) {
            errors += 1;
        }
        if (!debugLogs.contains('Will insert the created records of [FObjectOne__c].')) {
            errors += 2;
        }

        System.assertEquals(0, errors, 'insertRecords - errors found');
    }

    @IsTest
    private static void deleteRecords_hasNoRecordsToDelete_expectSuccess() {
        Integer numJobs = 1;
        Map<String, FObject> template = template1();

        Test.startTest();
        getFObjectAsync(template, 0, 0, numJobs, PARTITION_FIELD_VALUE)
            .deleteRecords();
        Test.stopTest();

        List<FObjectOne__c> records = [SELECT Id FROM FObjectOne__c];
        Boolean result = FObjectAsync.processIsValid() && records.size() == 0;
        System.assert(result == true, 'deleteRecords - errors found');
    }

    @IsTest
    private static void deleteRecords_hasRecordsToDeleteWithPartitioning_expectSuccess() {
        Integer numJobs = 2;

        // insert records with 2 partitions
        Map<String, FObject> template = template2();
        template.get('FObjectTwos')
            .setNumberOfRecords(100)
            .setDefinition(FObjectTwo__c.RecordTypeId, 'static value(RecordTypeA)')
            .setDefinition(FObjectTwo__c.ForceeaPartition__c, 'static value(' + PARTITION_FIELD_VALUE + '1)')
            .setPartitionFieldName(FObjectTwo__c.ForceeaPartition__c)
            .insertRecords(true);
        template.get('FObjectTwos')
            .setNumberOfRecords(101)
            .deleteDefinitions(FObjectTwo__c.ForceeaPartition__c)
            .setDefinition(FObjectTwo__c.ForceeaPartition__c, 'static value(' + PARTITION_FIELD_VALUE + '2)')
            .insertRecords(true);

        Test.startTest();
        getFObjectAsync(template, 0, 0, numJobs, PARTITION_FIELD_VALUE)
            .deleteRecords();
        Test.stopTest();

        List<FObjectTwo__c> records = [SELECT Id FROM FObjectTwo__c];
        Boolean result = records.size() == 1;
        System.assert(result == true, 'deleteRecords - errors found');
    }

    @IsTest
    private static void deleteRecords_hasRecordsToDeleteWithMixedPartitioning1_expectSuccess() {
        Integer numJobs = 2;

        // insert records with 1 partition
        Map<String, FObject> template = template2();
        template.get('FObjectTwos')
            .setNumberOfRecords(10)
            .setDefinition(FObjectTwo__c.RecordTypeId, 'static value(RecordTypeA)')
            .setDefinition(FObjectTwo__c.ForceeaPartition__c, 'static value(' + PARTITION_FIELD_VALUE + '1)')
            .setPartitionFieldName(FObjectTwo__c.ForceeaPartition__c)
            .insertRecords(true);
        template.get('FObjectTwos')
            .setNumberOfRecords(1)
            .deleteDefinitions(FObjectTwo__c.ForceeaPartition__c)
            .insertRecords(true);

        Test.startTest();
        // delete records with partition field value
        getFObjectAsync(template, 0, 0, numJobs, PARTITION_FIELD_VALUE)
            .deleteRecords();
        Test.stopTest();

        List<FObjectTwo__c> records = [SELECT Id FROM FObjectTwo__c];
        System.assert(records.size() == 1, 'deleteRecords - errors found');
    }

    @IsTest
    private static void deleteRecords_hasRecordsToDeleteWithMixedPartitioning2_expectSuccess() {
        Integer numJobs = 2;

        // insert records with 2 partitions
        Map<String, FObject> template = template2();
        template.get('FObjectTwos')
            .setNumberOfRecords(10)
            .setDefinition(FObjectTwo__c.RecordTypeId, 'static value(RecordTypeA)')
            .setDefinition(FObjectTwo__c.ForceeaPartition__c, 'static value(1)')
            .setPartitionFieldName(FObjectTwo__c.ForceeaPartition__c)
            .insertRecords(true);
        template.get('FObjectTwos')
            .setNumberOfRecords(101)
            .deleteDefinitions(FObjectTwo__c.ForceeaPartition__c)
            .setDefinition(FObjectTwo__c.ForceeaPartition__c, 'static value(2)')
            .insertRecords(true);

        Test.startTest();
        // delete records without partition field value
        getFObjectAsync(template, 0, 0, numJobs, '')
            .deleteRecords();
        Test.stopTest();

        List<FObjectTwo__c> records = [SELECT Id FROM FObjectTwo__c];
        System.assert(records.size() == 1, 'deleteRecords - errors found');
    }

    @IsTest
    private static void deleteRecords_hasRecordsToDeleteWithMixedPartitioning3_expectSuccess() {
        Integer numJobs = 2;

        // insert records without partitions
        Map<String, FObject> template = template2();
        template.get('FObjectTwos')
            .setNumberOfRecords(100)
            .setDefinition(FObjectTwo__c.RecordTypeId, 'static value(RecordTypeA)')
            .insertRecords(true);
        template.get('FObjectTwos')
            .setNumberOfRecords(101)
            .insertRecords(true);

        Test.startTest();
        // delete records with partition field value
        getFObjectAsync(template, 0, 0, numJobs, PARTITION_FIELD_VALUE)
            .deleteRecords();
        Test.stopTest();

        List<FObjectTwo__c> records = [SELECT Id FROM FObjectTwo__c];
        System.assert(records.size() == 101, 'deleteRecords - errors found');
    }

    @IsTest
    private static void deleteRecords_hasRecordsToDeleteWithoutPartitioning_expectSuccess() {
        Integer numJobs = 2;

        // insert records without partitions
        Map<String, FObject> template = template2();
        template.get('FObjectTwos')
            .setNumberOfRecords(100)
            .setDefinition(FObjectTwo__c.RecordTypeId, 'static value(RecordTypeA)')
            .insertRecords(true);
        template.get('FObjectTwos')
            .setNumberOfRecords(201)
            .insertRecords(true);

        Test.startTest();
        // delete records without partition field value
        getFObjectAsync(template, 0, 0, numJobs, '')
            .deleteRecords();
        Test.stopTest();

        List<FObjectTwo__c> records = [SELECT Id FROM FObjectTwo__c];
        System.assert(records.size() == 201, 'deleteRecords - errors found');
    }

    @IsTest
    private static void excludeOnAsyncDelete_excludeChild_expectSuccess() {
        Integer numJobs = 2;

        Map<String, FObject> template = template1();
        template.get('FObjectOnes').excludeOnAsyncDelete(true);
        FObject.insertRecordsFromTemplate(template, true);

        Test.startTest();
        getFObjectAsync(template, 0, 0, numJobs, '')
            .deleteRecords();
        Test.stopTest();

        Integer numRecords1 = [SELECT Id FROM FObjectOne__c].size();
        Integer numRecords2 = [SELECT Id FROM FObjectTwo__c].size();
        System.assertEquals(template.get('FObjectOnes').getNumberOfRecords(),
            numRecords1, 'excludeOnAsyncDelete - errors found');
        System.assertEquals(template.get('FObjectTwos').getNumberOfRecords(),
            numRecords2, 'excludeOnAsyncDelete - errors found');
    }

    @IsTest
    private static void excludeOnAsyncDelete_excludeParent_expectSuccess() {
        Integer numJobs = 2;

        Map<String, FObject> template = template1();
        template.get('FObjectTwos').excludeOnAsyncDelete(true);
        FObject.insertRecordsFromTemplate(template, true);

        Test.startTest();
        getFObjectAsync(template, 0, 0, numJobs, '')
            .deleteRecords();
        Test.stopTest();

        Integer numRecords1 = [SELECT Id FROM FObjectOne__c].size();
        Integer numRecords2 = [SELECT Id FROM FObjectTwo__c].size();
        System.assertEquals(0, numRecords1, 'excludeOnAsyncDelete - errors found');
        System.assertEquals(template.get('FObjectTwos').getNumberOfRecords(),
            numRecords2, 'excludeOnAsyncDelete - errors found');
    }

    @IsTest
    private static void getGroupName_invalidDefinitionWithValidationAndBenchmark_expectSuccess() {
        Integer numIterations = 10;
        Integer maxIterationsPerBatch = 10;

        Test.startTest();
        new FObjectAsync(template3())
            .setNumberOfIterations(numIterations)
            .setNumberOfJobs(1)
            .setMaxNumberOfIterationsPerBatch(maxIterationsPerBatch)
            .setPartitionFieldValue('df')
            .insertRecords();
        Test.stopTest();

        List<FObjectOne__c> records = [SELECT Id FROM FObjectOne__c];
        System.assert(records.isEmpty(), 'getGroupName - errors found');
    }

    @IsTest
    private static void getPartitionFieldValue_valid_expectSuccess() {
        Integer numIterations = 10;
        Integer maxIterationsPerBatch = 10;
        String partitionFieldValue = 'df';

        Test.startTest();
        FObjectAsync async = new FObjectAsync(template3())
            .setNumberOfIterations(numIterations)
            .setNumberOfJobs(1)
            .setMaxNumberOfIterationsPerBatch(maxIterationsPerBatch)
            .setPartitionFieldValue(partitionFieldValue);
        Test.stopTest();

        Boolean result = async.getPartitionFieldValue() == partitionFieldValue;
        System.assert(result == true, 'getPartitionFieldValue - errors found');
    }

    @IsTest
    private static void setProcessIsValid_isInvalid_expectSuccess() {
        Test.startTest();
        FObjectAsync async = new FObjectAsync(template3());
        FObjectAsync.setProcessIsValid(false);
        Test.stopTest();

        System.assert(FObjectAsync.processIsValid() == false, 'setProcessIsValid - errors found');
    }

    @IsTest
    private static void setProcessIsValid_isValid_expectSuccess() {
        Test.startTest();
        FObjectAsync async = new FObjectAsync(template3());
        Test.stopTest();

        System.assert(FObjectAsync.processIsValid() == true, 'setProcessIsValid - errors found');
    }

    @IsTest
    private static void terminateAsyncProcess_valid_expectSuccess() {
        Test.startTest();
        FObjectAsync async = new FObjectAsync(template3());
        FObjectAsync.terminate();
        Test.stopTest();

        System.assert(FObjectAsync.processIsTerminated(), 'terminateAsyncProcess - errors found');
    }

    /* METHODS */

    private static FObjectAsync getFObjectAsync(Map<String, FObject> template, Integer maxIterationsPerBatch,
        Integer numIterations, Integer numJobs, String partitionFieldValue
    ) {
        if (maxIterationsPerBatch == -999) {
            return new FObjectAsync(template)
                .setNumberOfIterations(numIterations)
                .setNumberOfJobs(numJobs)
                .setPartitionFieldValue(partitionFieldValue);
        } else {
            return new FObjectAsync(template)
                .setMaxNumberOfIterationsPerBatch(maxIterationsPerBatch)
                .setNumberOfIterations(numIterations)
                .setNumberOfJobs(numJobs)
                .setPartitionFieldValue(partitionFieldValue);
        }
    }

    /* TEMPLATES */

    private static Map<String, FObject> template1() {
        Map<String, FObject> template = new Map<String, FObject>();

        template.putAll(template2());
        template.put('FObjectOnes', new FObject(FObjectOne__c.SObjectType)
            .setNumberOfRecords(FOBJECT1_NUM_RECORDS)
            .setDefinition(FObjectOne__c.TestIntegerUnique__c, 'serial type(number) from(1) step(1) scale(0)')
            .setDefinition(FObjectOne__c.TestLookup__c, 'random lookup(FObjectTwo__c) source(forceea)')
            .setDefinition(FObjectOne__c.TestText__c,
                'random type(string) minLength(10) maxLength(30) startWith(lower) include(lower,upper,digit)')
            .setDefinition(FObjectOne__c.TestTextRequired__c, 'static value(test)')
            .setPartitionFieldName(FObjectOne__c.ForceeaPartition__c)
            .setGroupName('Group1')
        );

        return template;
    }

    private static Map<String, FObject> template1Invalid() {
        return new Map<String, FObject>{
            'FObjectOnes' => new FObject(FObjectOne__c.SObjectType)
                .setDefinition(FObjectOne__c.TestText__c, 'staticx value(test)')
        };
    }

    private static Map<String, FObject> template2() {
        Map<String, FObject> template = new Map<String, FObject>();

        template.put('FObjectTwos', new FObject(FObjectTwo__c.SObjectType)
            .setNumberOfRecords(FOBJECT2_NUM_RECORDS)
            .setDefinition(FObjectTwo__c.TestText__c, 'random type(number) from(10) to(100) scale(0)')
            .setDefinition(FObjectTwo__c.TestTextUnique__c, 'serial type(number) from(1) step(1) scale(0)')
            .setDefinition(FObjectTwo__c.TestPicklistDRequired__c, 'random type(picklist)')
            .setGroupName('Group2')
        );

        return template;
    }

    private static Map<String, FObject> template3() {
        return new Map<String, FObject>{
            'FObjectOnes' => new FObject(FObjectOne__c.SObjectType)
                .setNumberOfRecords(FOBJECT1_NUM_RECORDS)
                .setPartitionFieldName(FObjectOne__c.ForceeaPartition__c)
                .setDefinition(FObjectOne__c.TestText__c, 'static value(test)')
                .setDefinition(FObjectOne__c.TestTextRequired__c, 'static value(test)')
        };
    }

    private static Map<String, FObject> templateVariables() {
        return new Map<String, FObject>{
            'FObjectOnes' => new FObject(FObjectOne__c.SObjectType)
                .setVariable('localVar', 'local')
                .setNumberOfRecords(FOBJECT1_NUM_RECORDS)
                .setPartitionFieldName(FObjectOne__c.ForceeaPartition__c)
                .setDefinition(FObjectOne__c.TestText__c, 'static value({@localVar} - {@globalVar})')
                .setDefinition(FObjectOne__c.TestTextRequired__c, 'static value(test)')
        };
    }

    private static Map<String, FObject> templateWithoutRequiredFields() {
        return new Map<String, FObject>{
            'FObjectOnes' => new FObject(FObjectOne__c.SObjectType)
                .setNumberOfRecords(FOBJECT1_NUM_RECORDS)
                .setPartitionFieldName(FObjectOne__c.ForceeaPartition__c)
        };
    }

    private static Map<String, FObject> templateSetRequiredFields() {
        return new Map<String, FObject>{
            'FObjectOnes' => new FObject(FObjectOne__c.SObjectType)
                .setNumberOfRecords(FOBJECT1_NUM_RECORDS)
                .setPartitionFieldName(FObjectOne__c.ForceeaPartition__c)
                .setRequiredFields(true)
        };
    }

}
