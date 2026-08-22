import { NextResponse } from "next/server";
import { uploadedJobListings } from "@/lib/job-store";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const type = searchParams.get("type");

  let items = [...uploadedJobListings];

  if (type) {
    items = items.filter((j) => j.type.toUpperCase() === type.toUpperCase());
  }

  return NextResponse.json(items);
}
