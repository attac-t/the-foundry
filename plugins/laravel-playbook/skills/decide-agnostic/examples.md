# Agnostic: Examples

Real-world examples from the framework and production code.

---

## Framework Examples

### Agnostic: Flysystem (League)
**Why?** File storage is a PHP problem, not a Laravel problem.
```php
// Core: framework-free interface
interface FilesystemAdapter
{
    public function write(string $path, string $contents, Config $config): void;
    public function read(string $path): string;
    // ...
}

// Adapter: S3 implementation (separate package)
class AwsS3V3Adapter implements FilesystemAdapter { /* ... */ }

// Bridge: Laravel wraps it with ergonomics
class FilesystemAdapter implements CloudFilesystemContract
{
    public function __construct(FilesystemOperator $driver, FlysystemAdapter $adapter) {}
    public function url(string $path): string { /* ... */ }
    public function temporaryUrl(string $path, $expiration): string { /* ... */ }
}
```

### Laravel-Only: Spatie Permission
**Why?** The value IS the Eloquent integration.
```php
class User extends Model
{
    use HasRoles;
}

$user->assignRole('admin');
$user->hasPermissionTo('edit articles');
```

---

## Production Patterns

### The Three-Package Split
```text
league/flysystem              # Core: interfaces
league/flysystem-aws-s3-v3    # Adapter: S3
illuminate/filesystem          # Bridge: Storage facade
```
Each layer versions independently. Core defines interfaces. Adapters implement them. Bridge adds framework wiring.

### The Bridge Is Thin
```php
Storage::extend('dropbox', function ($app, $config) {
    $adapter = new DropboxAdapter($client);
    return new FilesystemAdapter(new Filesystem($adapter, $config), $adapter, $config);
});
```
No business logic in the bridge. Ever.

### Interface Segregation
```php
interface FilesystemReader
{
    public function read(string $path): string;
    public function fileExists(string $path): bool;
    // ...
}

interface FilesystemWriter
{
    public function write(string $path, string $contents, array $config = []): void;
    public function delete(string $path): void;
    // ...
}

interface FilesystemOperator extends FilesystemReader, FilesystemWriter {}
```
Type-hint `FilesystemReader` when you only read. Small interfaces are easy to implement, easy to swap.

### PSR as Portability Lever
```text
league/container     -> PSR-11 (Container)
league/route         -> PSR-7, PSR-15 (HTTP)
league/event         -> PSR-14 (Event Dispatcher)
```
Implement a PSR, work with any framework that consumes it.

### When You Don't Need a Bridge
```php
// league/csv -- no service provider, no config, no container
$csv = Reader::createFromPath('/path/to/data.csv', 'r');
$csv->setHeaderOffset(0);

foreach ($csv->getRecords() as $record) {
    // ...
}
```
If your package doesn't touch the container, skip the bridge. `new` it and use it.

### Contract Testing for Adapters
```php
class S3AdapterTest extends FilesystemAdapterTestCase
{
    protected static function createFilesystemAdapter(): FilesystemAdapter
    {
        return new AwsS3V3Adapter($s3Client, $bucket);
    }
}
```
One abstract method. The base class runs 40+ integration tests. Ship contract test utilities with your agnostic core.
