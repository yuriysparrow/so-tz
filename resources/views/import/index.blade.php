<!doctype html>
<html lang="uk">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Імпорт</title>
    <style>
        :root {
            --bg: #f5f6f8;
            --card: #fff;
            --text: #1c1f24;
            --muted: #6b7280;
            --line: #d9dde3;
            --accent: #2563eb;
            --ok: #15803d;
            --okbg: #ecfdf3;
            --err: #b91c1c;
            --errbg: #fef2f2;
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #111418;
                --card: #1a1e24;
                --text: #e8eaed;
                --muted: #9aa3af;
                --line: #2c323b;
                --accent: #3b82f6;
                --ok: #4ade80;
                --okbg: #10261a;
                --err: #f87171;
                --errbg: #2a1515;
            }
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 24px;
            background: var(--bg);
            color: var(--text);
            font: 16px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
        }

        .card {
            width: 100%;
            max-width: 560px;
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 28px;
        }

        h1 {
            margin: 0 0 4px;
            font-size: 22px;
        }

        .hint {
            margin: 0 0 20px;
            color: var(--muted);
            font-size: 14px;
        }

        .alert {
            border-radius: 8px;
            padding: 12px 14px;
            margin-bottom: 16px;
            font-size: 14px;
        }

        .alert.ok {
            background: var(--okbg);
            color: var(--ok);
        }

        .alert.err {
            background: var(--errbg);
            color: var(--err);
        }

        .stats {
            width: 100%;
            margin-top: 8px;
            border-collapse: collapse;
            color: var(--text);
        }

        .stats td {
            padding: 3px 0;
        }

        .stats td:last-child {
            text-align: right;
            font-variant-numeric: tabular-nums;
        }

        input[type=file] {
            width: 100%;
            padding: 14px;
            border: 2px dashed var(--line);
            border-radius: 8px;
            background: transparent;
            color: var(--text);
        }

        button {
            width: 100%;
            margin-top: 16px;
            padding: 12px;
            border: 0;
            border-radius: 8px;
            background: var(--accent);
            color: #fff;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
        }

        button:disabled {
            opacity: .6;
            cursor: wait;
        }
    </style>
</head>
<body>
<main class="card">
    <h1>Імпорт з XLSX</h1>
    <p class="hint">
        Перший рядок - заголовки. Порядок стовпчиків: external_id, created_at, first_name, last_name, phone, email,
        city, source, utm_campaign, product, budget_uah, status, manager, comment, next_contact_at
    </p>

    @if (session('import_stats'))
        @php($s = session('import_stats'))
        <div class="alert ok">
            <strong>Імпорт завершено</strong>
            <table class="stats">
                <tr>
                    <td>Рядків імпортовано</td>
                    <td>{{ number_format($s['rows'], 0, '.', ' ') }}</td>
                </tr>
                <tr>
                    <td>Всього</td>
                    <td>{{ $s['total'] }} с</td>
                </tr>
                <tr>
                    <td>Читання файлів</td>
                    <td>{{ $s['parse'] }} с</td>
                </tr>
                <tr>
                    <td>Запис в базу даних</td>
                    <td>{{ $s['insert'] }} секунд</td>
                </tr>
                <tr>
                    <td>Швидкість</td>
                    <td>{{ number_format($s['rps'], 0, '.', ' ') }} рядків/секунд</td>
                </tr>
            </table>
        </div>
    @endif

    @if ($errors->any())
        <div class="alert err">
            @foreach ($errors->all() as $error)
                <div>{{ $error }}</div>
            @endforeach
        </div>
    @endif

    <form id="import-form" method="POST" action="{{ route('import.store') }}" enctype="multipart/form-data">
        @csrf
        <input type="file" name="file" accept=".xlsx" required>
        <button type="submit" id="submit-btn">Імпортувати</button>
    </form>
</main>

<script>
    document.getElementById('import-form').addEventListener('submit', function () {
        let btn = document.getElementById('submit-btn');
        btn.disabled = true;
        btn.textContent = 'Імпорт... Не закривайте сторінку';
    });
</script>
</body>
</html>
