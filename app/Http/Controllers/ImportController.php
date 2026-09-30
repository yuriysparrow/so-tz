<?php

namespace App\Http\Controllers;

use App\Services\CustomerXlsxImporter;
use Brick\Money\Money;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Illuminate\Support\LazyCollection;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Throwable;

class ImportController extends Controller
{
    public function create(): View
    {
        return view('import.index');
    }

    public function store(Request $request, CustomerXlsxImporter $importer): RedirectResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx', 'max:51200'],
        ]);

        $relative = $request->file('file')->storeAs('imports', Str::uuid() . '.xlsx');

        try {
            $stats = $importer->import(Storage::path($relative));
        } catch (Throwable $e) {
            report($e);

            return back()->withErrors([
                'file' => 'Помилка імпорту:' . Str::limit($e->getMessage(), 300),
            ]);
        } finally {
            Storage::delete($relative);
        }

        return redirect()
            ->route('import.create')
            ->with('import_stats', $stats);
    }
}
