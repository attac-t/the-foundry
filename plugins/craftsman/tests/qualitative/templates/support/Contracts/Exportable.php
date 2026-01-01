<?php

declare(strict_types=1);

namespace Support\Contracts;

interface Exportable
{
    /**
     * @return array<string, mixed>
     */
    public function toExport(): array;
}
