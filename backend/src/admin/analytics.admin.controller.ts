import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('admin-analytics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPER_ADMIN')
@Controller('admin/analytics')
export class AnalyticsAdminController {
  constructor(private prisma: PrismaService) {}

  @Get('overview')
  async overview() {
    const [students, notes, jobListings, results] = await Promise.all([
      this.prisma.user.count({ where: { role: 'STUDENT' } }),
      this.prisma.academicContent.count(),
      this.prisma.jobListing.count(),
      this.prisma.result.count(),
    ]);
    return { students, notes, jobListings, results };
  }

  @Get('recent-uploads')
  async recentUploads() {
    const [recentNotes, recentJobs, recentResults] = await Promise.all([
      this.prisma.academicContent.findMany({
        take: 10,
        orderBy: { uploadedAt: 'desc' },
        include: { subject: true },
      }),
      this.prisma.jobListing.findMany({
        take: 10,
        orderBy: { postedAt: 'desc' },
      }),
      this.prisma.result.findMany({
        take: 10,
        orderBy: { uploadedAt: 'desc' },
      }),
    ]);
    return { recentNotes, recentJobs, recentResults };
  }
}
