# Agnostic: Examples

Real-world examples from the framework and production packages.

---

## Framework Examples

### Agnostic: Flysystem (League / Frank de Jonge)
**Why?** File storage is a PHP problem, not a Laravel problem.
```php
// Core: framework-free interfaces
interface FilesystemAdapter
{
    public function write(string $path, string $contents, Config $config): void;
    public function read(string $path): string;
    public function delete(string $path): void;
    // ... 14 more methods
}

// Adapter: S3 implementation (separate package)
class AwsS3V3Adapter implements FilesystemAdapter { /* ... */ }

// Bridge: Laravel wraps it with ergonomics
class FilesystemAdapter implements CloudFilesystemContract
{
    public function __construct(
        FilesystemOperator $driver,  // Flysystem core
        FlysystemAdapter $adapter,
        array $config = []
    ) {}

    // Laravel-specific convenience
    public function url(string $path): string { /* ... */ }
    public function temporaryUrl(string $path, $expiration): string { /* ... */ }
}
```
Three layers: core (interfaces), adapter (implementations), bridge (framework ergonomics). One core serves Laravel, Symfony, and standalone PHP.

### Laravel-Only: Spatie Permission
**Why?** The value IS the Eloquent integration.
```php
// Trait on a model — deeply coupled to Eloquent
class User extends Model
{
    use HasRoles;
}

$user->assignRole('admin');
$user->hasPermissionTo('edit articles');
```
Roles and permissions are stored via Eloquent relationships, cached via Laravel's cache, authorized via Laravel's Gate. There is no framework-agnostic "permission" problem worth solving separately.

---

## Production Patterns

### The Three-Package Split (League Pattern)
```
league/flysystem              # Core: interfaces + Filesystem class
league/flysystem-aws-s3-v3    # Adapter: S3 implementation
illuminate/filesystem          # Bridge: Laravel Storage facade
```
```
eventsauce/eventsauce                  # Core: event sourcing interfaces
eventsauce/message-repository-for-illuminate  # Adapter: Eloquent persistence
eventsauce/laravel-eventsauce          # Bridge: service provider
```
Each layer versions independently. The core defines interfaces. Adapters implement them. The bridge adds framework wiring.

### The Bridge Is Thin
```php
// Laravel's bridge for Flysystem — adds ergonomics, not logic
Storage::extend('dropbox', function ($app, $config) {
    $adapter = new DropboxAdapter($client);
    return new FilesystemAdapter(
        new Filesystem($adapter, $config),
        $adapter,
        $config
    );
});
```
The bridge maps config to adapters, registers the service provider, and wraps the core in a facade. No business logic in the bridge. Ever.

### Interface Segregation (Flysystem)
```php
interface FilesystemReader
{
    public function read(string $path): string;
    public function fileExists(string $path): bool;
    // ... read-only methods
}

interface FilesystemWriter
{
    public function write(string $path, string $contents, array $config = []): void;
    public function delete(string $path): void;
    // ... write-only methods
}

interface FilesystemOperator extends FilesystemReader, FilesystemWriter {}
```
Type-hint `FilesystemReader` when you only read. `FilesystemWriter` when you only write. `FilesystemOperator` when you need both. Small interfaces are easy to implement, easy to swap.

### PSR as Portability Lever
```
league/container     → PSR-11 (Container)
league/route         → PSR-7, PSR-15 (HTTP)
league/event         → PSR-14 (Event Dispatcher)
league/oauth2-server → PSR-7 (HTTP Messages)
```
Implement a PSR, work with any framework that consumes it. PSRs are the interoperability layer that makes framework-agnostic design viable.

### When You Don't Need a Bridge
```php
// league/csv — no service provider, no config, no container
$csv = Reader::createFromPath('/path/to/data.csv', 'r');
$csv->setHeaderOffset(0);

foreach ($csv->getRecords() as $record) {
    // Process
}
```
If your package doesn't touch the container, skip the bridge. Not every package needs a service provider. `new` it and use it.

### Contract Testing for Adapters (Flysystem)
```php
use League\Flysystem\AdapterTestUtilities\FilesystemAdapterTestCase;

class S3AdapterTest extends FilesystemAdapterTestCase
{
    protected static function createFilesystemAdapter(): FilesystemAdapter
    {
        return new AwsS3V3Adapter($s3Client, $bucket);
    }
}
```
One abstract method. The base class runs 40+ integration tests. Every adapter runs the same tests. If it passes, it works. Ship contract test utilities with your agnostic core so adapter authors can verify compliance.
