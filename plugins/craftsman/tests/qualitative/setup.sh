#!/bin/bash
#
# Qualitative Test Environment Setup
# Creates a Laravel DDD scaffold for plugin testing
#

set -e

TEST_ENV="/tmp/craftsman-test-env"

echo "==> Setting up qualitative test environment at $TEST_ENV"

# Clean and create
if [ -d "$TEST_ENV" ]; then
    echo "    Resetting existing environment..."
    cd "$TEST_ENV"
    git reset --hard HEAD 2>/dev/null || true
    git clean -fd 2>/dev/null || true
else
    echo "    Creating fresh environment..."
    mkdir -p "$TEST_ENV"
    cd "$TEST_ENV"
    git init
fi

# Create Laravel DDD structure
echo "==> Creating Laravel DDD scaffold..."

# App layer (thin)
mkdir -p app/Http/Controllers
mkdir -p app/Providers

# Domain layer (business logic)
mkdir -p domain/Orders/Actions
mkdir -p domain/Orders/Models
mkdir -p domain/Orders/DTOs
mkdir -p domain/Orders/QueryBuilders

mkdir -p domain/Users/Actions
mkdir -p domain/Users/Models
mkdir -p domain/Users/DTOs

# Support layer (shared utilities)
mkdir -p support/Contracts
mkdir -p support/Concerns

# Routes
mkdir -p routes

# Create stub files for context

# Controller stub
cat > app/Http/Controllers/OrderController.php << 'EOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function index()
    {
        // TODO: List orders
    }

    public function store(Request $request)
    {
        // TODO: Create order
    }
}
EOF

# Model stub
cat > domain/Orders/Models/Order.php << 'EOF'
<?php

namespace Domain\Orders\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $fillable = [
        'user_id',
        'status',
        'total',
        'starts_at',
        'ends_at',
    ];

    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];
}
EOF

# QueryBuilder stub
cat > domain/Orders/QueryBuilders/OrderQuery.php << 'EOF'
<?php

namespace Domain\Orders\QueryBuilders;

use Illuminate\Database\Eloquent\Builder;

class OrderQuery extends Builder
{
    public function forUser(int $userId): self
    {
        return $this->where('user_id', $userId);
    }

    public function withStatus(string $status): self
    {
        return $this->where('status', $status);
    }
}
EOF

# User model stub
cat > domain/Users/Models/User.php << 'EOF'
<?php

namespace Domain\Users\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    protected $fillable = [
        'name',
        'email',
        'password',
    ];
}
EOF

# Routes stub
cat > routes/api.php << 'EOF'
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\OrderController;

Route::prefix('orders')->group(function () {
    Route::get('/', [OrderController::class, 'index']);
    Route::post('/', [OrderController::class, 'store']);
});

// TODO: Add more routes
EOF

# Support trait example
cat > support/Concerns/HasUuid.php << 'EOF'
<?php

namespace Support\Concerns;

use Illuminate\Support\Str;

trait HasUuid
{
    protected static function bootHasUuid(): void
    {
        static::creating(function ($model) {
            $model->uuid = Str::uuid();
        });
    }
}
EOF

# Contract example
cat > support/Contracts/Exportable.php << 'EOF'
<?php

namespace Support\Contracts;

interface Exportable
{
    public function toExport(): array;
}
EOF

# Commit initial state
git add -A
git commit -m "Initial Laravel DDD scaffold for testing" 2>/dev/null || true

echo "==> Test environment ready at $TEST_ENV"
echo "    Structure:"
find . -type f -name "*.php" | head -20 | sed 's/^/    /'
