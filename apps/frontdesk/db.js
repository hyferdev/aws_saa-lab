// In-memory store. Replaced by RDS in sprint 6.
import { v4 as uuidv4 } from 'uuid';

const visits = new Map();

export function createVisit({ visitor_name, host_name, company, purpose }) {
  const visit = {
    id: uuidv4(),
    visitor_name,
    host_name,
    company: company || null,
    purpose: purpose || null,
    checked_in_at: new Date().toISOString(),
    checked_out_at: null,
  };
  visits.set(visit.id, visit);
  return visit;
}

export function checkoutVisit(id) {
  const visit = visits.get(id);
  if (!visit) return null;
  visit.checked_out_at = new Date().toISOString();
  return visit;
}

export function getVisit(id) {
  return visits.get(id) || null;
}

export function getTodayVisits() {
  const today = new Date().toDateString();
  return [...visits.values()].filter(
    (v) => new Date(v.checked_in_at).toDateString() === today
  );
}

export function getTodaySummary() {
  const today = getTodayVisits();
  return {
    total: today.length,
    checked_in: today.filter((v) => !v.checked_out_at).length,
    checked_out: today.filter((v) => v.checked_out_at).length,
  };
}
