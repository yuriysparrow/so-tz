<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use RuntimeException;
use Vtiful\Kernel\Excel;

class CustomerXlsxImporter
{
    private const int BATCH_SIZE = 2000;
    private const int COLUMNS = 15;

    public function import(string $path): array
    {
        $excel = $this->open($path);
        $blank = array_fill(0, self::COLUMNS, null);

        $connection = DB::connection();
        $logging = $connection->logging();
        $connection->disableQueryLog();

        $t0 = microtime(true);
        $insertTime = 0.0;
        $rows = 0;
        $batch = [];

        $flush = function () use (&$batch, &$insertTime, &$rows) {
            $s = microtime(true);
            DB::table('customers')->insert($batch);
            $insertTime += microtime(true) - $s;
            $rows += count($batch);
            $batch = [];
        };

        DB::beginTransaction();

        try {
            while (($row = $excel->nextRow()) !== null) {
                if ($row === []) {
                    continue;
                }

                $row = array_replace($blank, $row);
                if ($row[0] === null || $row[0] === '') {
                    continue;
                }

                $batch[] = $this->mapRow($row);

                if (count($batch) >= self::BATCH_SIZE) {
                    $flush();
                }
            }

            if ($batch) {
                $flush();
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        } finally {
            if ($logging) {
                $connection->enableQueryLog();
            }
        }

        $total = microtime(true) - $t0;

        return [
            'rows' => $rows,
            'total' => round($total, 2),
            'insert' => round($insertTime, 2),
            'parse' => round($total - $insertTime, 2),
            'rps' => $total > 0 ? (int)($rows / $total) : 0,
        ];
    }

    public function preview(string $path, int $limit = 3): array
    {
        $excel = $this->open($path);
        $blank = array_fill(0, self::COLUMNS, null);
        $out = [];

        while (count($out) < $limit && ($row = $excel->nextRow()) !== null) {
            if ($row === []) {
                continue;
            }
            $out[] = $this->mapRow(array_replace($blank, $row));
        }

        return $out;
    }

    private function open(string $path): Excel
    {
        if (!extension_loaded('xlswriter')) {
            throw new RuntimeException('Extension xlswriter not installed.');
        }
        if (!is_file($path)) {
            throw new RuntimeException("File not found: {$path}");
        }

        $excel = new Excel(['path' => dirname($path)]);
        $excel->openFile(basename($path))->openSheet();
        $excel->nextRow();

        $excel->setType([
            Excel::TYPE_STRING,
            Excel::TYPE_TIMESTAMP,
            Excel::TYPE_STRING,
            Excel::TYPE_STRING,
            Excel::TYPE_INT,
            Excel::TYPE_STRING,
            Excel::TYPE_STRING,
            Excel::TYPE_STRING,
            Excel::TYPE_STRING,
            Excel::TYPE_STRING,
            Excel::TYPE_INT,
            Excel::TYPE_STRING,
            Excel::TYPE_STRING,
            Excel::TYPE_STRING,
            Excel::TYPE_TIMESTAMP,
        ]);

        return $excel;
    }

    private function mapRow(array $r): array
    {
        return [
            'external_id' => $r[0],
            'created_at' => $this->date($r[1]),
            'first_name' => $this->nullable($r[2]),
            'last_name' => $this->nullable($r[3]),
            'phone' => $this->phone($r[4]),
            'email' => $this->nullable($r[5]),
            'city' => $this->nullable($r[6]),
            'source' => $this->nullable($r[7]),
            'utm_campaign' => $this->nullable($r[8]),
            'product' => $this->nullable($r[9]),
            'budget_uah' => $this->nullable($r[10]),
            'status' => $this->nullable($r[11]),
            'manager' => $this->nullable($r[12]),
            'comment' => $this->nullable($r[13]),
            'next_contact_at' => $this->date($r[14]),
        ];
    }

    private function nullable(mixed $v): mixed
    {
        return ($v === '' || $v === null) ? null : $v;
    }

    private function date(mixed $v): ?string
    {
        if ($v === '' || $v === null) {
            return null;
        }

        return (is_int($v) || is_float($v)) ? gmdate('Y-m-d H:i:s', (int)$v) : (string)$v;
    }

    private function phone(mixed $v): ?string
    {
        if ($v === '' || $v === null) {
            return null;
        }

        return (string)$v;
    }
}
