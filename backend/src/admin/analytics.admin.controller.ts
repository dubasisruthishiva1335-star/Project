import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { PrismaService } from '../prisma/prisma.service';

function isTestJob(job: any) {
  if (!job) return true;
  const title = (job.title || '').toLowerCase();
  const company = (job.company || '').toLowerCase();
  const url = (job.applyUrl || '').toLowerCase();
  return (
    title.includes('tspsc') ||
    title.includes('frontend') ||
    title.includes('acme') ||
    title.includes('html') ||
    title.includes('jhbb') ||
    company.includes('acme') ||
    company.includes('tspsc') ||
    url.includes('example.com')
  );
}

@ApiTags('admin-analytics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPER_ADMIN')
@Controller('admin/analytics')
export class AnalyticsAdminController {
  constructor(private prisma: PrismaService) {}

  @Get('overview')
  async overview() {
    const allJobs = await this.prisma.jobListing.findMany();
    const cleanJobs = allJobs.filter((j) => !isTestJob(j));

    const [students, notes, results] = await Promise.all([
      this.prisma.user.count({ where: { role: 'STUDENT' } }),
      this.prisma.academicContent.count(),
      this.prisma.result.count(),
    ]);

    return { students, notes, jobListings: cleanJobs.length, results };
  }

  @Get('recent-uploads')
  async recentUploads() {
    const [recentNotes, rawJobs, recentResults, allStudents] = await Promise.all([
      this.prisma.academicContent.findMany({
        orderBy: { uploadedAt: 'desc' },
        include: { subject: true },
      }),
      this.prisma.jobListing.findMany({
        orderBy: { postedAt: 'desc' },
      }),
      this.prisma.result.findMany({
        orderBy: { uploadedAt: 'desc' },
      }),
      this.prisma.user.findMany({
        where: { role: 'STUDENT' },
        select: { id: true, hallTicket: true, fullName: true, branch: true, semester: true, createdAt: true },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const recentJobs = rawJobs.filter((j) => !isTestJob(j));

    return { recentNotes, recentJobs, recentResults, allStudents };
  }
}
