import { moduleFor, test } from 'ember-qunit';

moduleFor('adapter:application', 'Unit | Adapter | application', {
    // Specify the other units that are required for this test.
    needs: ['service:tenant']
});

// Replace this with your real tests.
test('it exists', function(assert) {
    const adapter = this.subject();
    assert.ok(adapter);
});
