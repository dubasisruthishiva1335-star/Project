// lib/job-store.ts
// Shared in-memory store for Internships, Placements & Govt Jobs uploaded via Admin Web

export interface JobListingItem {
  id: string;
  title: string;
  company: string;
  type: "INTERNSHIP" | "PLACEMENT" | "GOVT_JOB";
  category?: string;
  applyUrl?: string;
  branch?: string;
  fileUrl?: string;
  stipend?: string;
  location?: string;
  deadline?: string;
  description?: string;
  postedAt: string;
}

// Clean initial store — 0 default items until admin uploads
export let uploadedJobListings: JobListingItem[] = [];

export function addJobListing(item: Omit<JobListingItem, "id" | "postedAt">) {
  const newListing: JobListingItem = {
    ...item,
    id: `job_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    postedAt: new Date().toISOString(),
  };
  uploadedJobListings.unshift(newListing);
  return newListing;
}

export function clearJobListings() {
  uploadedJobListings = [];
}
