# Grouping Util: Examples

---

## The Pipeline

```typescript
const sessionsByDay = (sessions: WorkSessionModel[]): DayGroup[] => {
  const grouped = groupSessionsByDate(sessions)
  return Object.entries(grouped)
    .map(([date, sessions]) => createDayGroup(date, sessions))
    .sort(sortByDateDesc)
}
```

---

## Step 1: Group

```typescript
const groupSessionsByDate = (sessions: WorkSessionModel[]) => {
  return sessions.reduce(
    (groups, session) => {
      const dayKey = getSessionDateKey(session)
      if (dayKey) {
        groups[dayKey] = groups[dayKey] || []
        groups[dayKey].push(session)
      }
      return groups
    },
    {} as Record<string, WorkSessionModel[]>
  )
}

const getSessionDateKey = (session: WorkSessionModel): string | null => {
  if (!session.started_at) return null
  const dateObj = parseDateTime(session.started_at)
  return dateObj.isValid ? dateObj.toISODate() : null
}
```

---

## Step 2: Transform

```typescript
interface DayGroup {
  date: string
  sessions: WorkSessionModel[]
  displayName: string
  formattedDate: string
  totals: DayTotals
}

const createDayGroup = (date: string, sessions: WorkSessionModel[]): DayGroup => ({
  date,
  sessions,
  displayName: formatDayDisplayName(date),
  formattedDate: isoDateToLocale(date, DateTime.DATE_MED) || date,
  totals: calculateDayTotals(sessions)
})

const calculateDayTotals = (sessions: WorkSessionModel[]) => ({
  totalSessions: sessions.length,
  totalMinutes: sessions.reduce((sum, s) => sum + (s.duration_minutes || 0), 0),
  activeSessions: sessions.filter(s => s.is_active).length
})
```

---

## Step 3: Sort

```typescript
const sortByDateDesc = (a: DayGroup, b: DayGroup) =>
  DateTime.fromISO(b.date).toMillis() - DateTime.fromISO(a.date).toMillis()
```
